import Speech
import AVFoundation
import Combine

/// Service for speech-to-text recognition
actor SpeechRecognizer: ObservableObject {
    static let shared = SpeechRecognizer()
    
    @Published @MainActor var isRecording = false
    @Published @MainActor var transcribedText = ""
    @Published @MainActor var errorMessage: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    // MARK: - Permissions
    
    func requestAuthorization() async -> Bool {
        // Request microphone permission
        let micStatus = await AVCaptureDevice.requestAccess(for: .audio)
        
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        return micStatus && speechStatus
    }
    
    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized &&
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    // MARK: - Recording
    
    func startRecording() async throws {
        guard isAuthorized else {
            throw SpeechError.notAuthorized
        }
        
        // Reset state on main actor
        await MainActor.run {
            transcribedText = ""
            errorMessage = nil
            isRecording = true
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                    self.isRecording = false
                }
                return
            }
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcribedText = transcript
                }
                
                // Stop if final result
                if result.isFinal {
                    Task { @MainActor in
                        self.isRecording = false
                    }
                }
            }
        }
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() async -> String {
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        await MainActor.run { isRecording = false }
        
        return await MainActor.run { transcribedText }
    }
    
    func cancelRecording() async {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        await MainActor.run {
            isRecording = false
            transcribedText = ""
        }
    }
}

// MARK: - Errors

enum SpeechError: LocalizedError {
    case notAuthorized
    case requestCreationFailed
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Microphone and speech recognition permissions required"
        case .requestCreationFailed:
            return "Failed to create speech recognition request"
        case .recognitionFailed:
            return "Speech recognition failed"
        }
    }
}
