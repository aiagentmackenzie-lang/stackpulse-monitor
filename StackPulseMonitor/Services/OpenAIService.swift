import Foundation

/// Service for OpenAI GPT-4o API integration
actor OpenAIService {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var apiKey: String?
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Chat Completion
    
    /// Send a chat message and get response
    func sendMessage(
        project: Project,
        messages: [AIMessage],
        systemPrompt: String? = nil
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw OpenAIError.notConfigured
        }
        
        // Build messages array for OpenAI
        var openAIMessages: [[String: String]] = []
        
        // System message with context
        if let system = systemPrompt {
            openAIMessages.append([
                "role": "system",
                "content": system
            ])
        }
        
        // Conversation history
        for message in messages {
            openAIMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": openAIMessages,
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        // Create request
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let httpResponse = response as? HTTPURLResponse
        guard (200...299).contains(httpResponse?.statusCode ?? 0) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.apiError("HTTP \(httpResponse?.statusCode ?? 0)")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content
    }
    
    // MARK: - Streaming (simplified)
    
    /// Send message and return streaming chunks
    func streamMessage(
        project: Project,
        messages: [AIMessage],
        systemPrompt: String? = nil
    ) async throws -> AsyncStream<String> {
        guard let apiKey = apiKey else {
            throw OpenAIError.notConfigured
        }
        
        var openAIMessages: [[String: String]] = []
        
        if let system = systemPrompt {
            openAIMessages.append([
                "role": "system",
                "content": system
            ])
        }
        
        for message in messages {
            openAIMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": openAIMessages,
            "temperature": 0.7,
            "max_tokens": 2000,
            "stream": true
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OpenAIError.apiError("Invalid response")
        }
        
        // Return async stream
        return AsyncStream { continuation in
            Task {
                do {
                    var buffer = Data()
                    for try await byte in bytes {
                        if byte == 10 { // newline
                            if let line = String(data: buffer, encoding: .utf8),
                               line.hasPrefix("data: ") {
                                let dataContent = String(line.dropFirst(6))
                                if dataContent == "[DONE]" {
                                    continuation.finish()
                                    return
                                }
                                
                                if let jsonData = dataContent.data(using: .utf8),
                                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let choices = json["choices"] as? [[String: Any]],
                                   let delta = choices.first?["delta"] as? [String: Any],
                                   let content = delta["content"] as? String {
                                    continuation.yield(content)
                                }
                            }
                            buffer.removeAll()
                        } else {
                            buffer.append(byte)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenAI API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}
