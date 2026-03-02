import SwiftUI

/// Main AI chat view per project
struct AIChatView: View {
    let project: Project
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var thread: AIThread
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var streamingMessageIndex: Int?
    
    init(project: Project, viewModel: AppViewModel) {
        self.project = project
        self.viewModel = viewModel
        // Get existing thread or create new
        if let existing = project.activeThreads.first {
            _thread = State(initialValue: existing)
        } else {
            _thread = State(initialValue: AIThread(projectId: project.id))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome if empty
                            if thread.messages.isEmpty {
                                WelcomeSection(project: project)
                                
                                // Spacer before quick prompts
                                Spacer(minLength: 32)
                                
                                // Quick prompts
                                QuickPromptsView(prompts: QuickPrompt.defaults) { promptText in
                                    inputText = promptText
                                    sendMessage()
                                }
                                .padding(.horizontal, 8)
                                
                                // Bottom spacer
                                Spacer(minLength: 20)
                            }
                            
                            ForEach(Array(thread.messages.enumerated()), id: \.element.id) { _, message in
                                ChatMessageBubble(
                                    message: message,
                                    isUser: message.role == .user
                                )
                                .id(message.id)
                            }
                            
                            // Bottom spacer for scrolling
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        scrollProxy = proxy
                        scrollToBottom()
                    }
                    .onChange(of: thread.messages.count) {
                        scrollToBottom()
                    }
                }
                
                // Input bar
                ChatInputBar(
                    text: $inputText,
                    onSend: sendMessage,
                    isStreaming: isStreaming
                )
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("\(project.name) Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.muted)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            clearThread()
                        } label: {
                            Label("Clear History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty, !isStreaming else { return }
        
        let userMessage = AIMessage(role: .user, content: inputText)
        let messageText = inputText
        
        // Add user message
        thread.messages.append(userMessage)
        inputText = ""
        
        // Check for OpenAI key
        guard !viewModel.openAIKey.isEmpty else {
            let errorMessage = AIMessage(
                role: .assistant,
                content: "⚠️ Please configure your OpenAI API key in Settings to use AI chat."
            )
            thread.messages.append(errorMessage)
            saveThread()
            return
        }
        
        // Configure and send
        Task {
            await OpenAIService.shared.configure(apiKey: viewModel.openAIKey)
            
            isStreaming = true
            
            // Create empty assistant message for streaming
            let streamingMessage = AIMessage(role: .assistant, content: "", isStreaming: true)
            await MainActor.run {
                thread.messages.append(streamingMessage)
            }
            let messageIndex = thread.messages.count - 1
            
            // Build system prompt with project context
            let systemPrompt = AIContextBuilder.buildSystemPrompt(for: project)
            let extraContext = AIContextBuilder.buildMessageContext(project: project, userMessage: messageText)
            
            let fullSystem = extraContext.isEmpty ? systemPrompt : "\(systemPrompt)\n\nCurrent context:\n\(extraContext)"
            
            do {
                // Stream response
                let stream = try await OpenAIService.shared.streamMessage(
                    project: project,
                    messages: thread.messages.filter { !$0.isStreaming },
                    systemPrompt: fullSystem
                )
                
                // Collect all content
                var fullContent = ""
                for await chunk in stream {
                    fullContent += chunk
                    await MainActor.run {
                        if thread.messages.indices.contains(messageIndex) {
                            thread.messages[messageIndex].content = fullContent
                        }
                    }
                }
                
                // Finalize
                await MainActor.run {
                    if thread.messages.indices.contains(messageIndex) {
                        thread.messages[messageIndex].isStreaming = false
                    }
                    thread.updatedAt = Date()
                    isStreaming = false
                    saveThread()
                }
                
            } catch {
                // Show error
                await MainActor.run {
                    if thread.messages.indices.contains(messageIndex) {
                        thread.messages[messageIndex].content = "❌ Error: \(error.localizedDescription)\n\nPlease check your OpenAI API key and try again."
                        thread.messages[messageIndex].isStreaming = false
                    }
                    thread.updatedAt = Date()
                    isStreaming = false
                    saveThread()
                }
            }
        }
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private func clearThread() {
        thread.messages.removeAll()
        thread.updatedAt = Date()
        saveThread()
    }
    
    private func saveThread() {
        // Update project in viewModel
        if let projectIndex = viewModel.projects.firstIndex(where: { $0.id == project.id }) {
            if let threadIndex = viewModel.projects[projectIndex].aiThreads.firstIndex(where: { $0.id == thread.id }) {
                viewModel.projects[projectIndex].aiThreads[threadIndex] = thread
            } else {
                viewModel.projects[projectIndex].aiThreads.append(thread)
            }
            viewModel.persistProjects()
        }
    }
}

// MARK: - Welcome Section

struct WelcomeSection: View {
    let project: Project
    
    var body: some View {
        VStack(spacing: 24) {
            // Header icon
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.purple)
            
            // Title
            Text("Ask me anything about \(project.name)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            
            // Divider for visual separation
            Divider()
                .background(Theme.border)
                .padding(.horizontal, 40)
                .padding(.vertical, 8)
            
            // Try asking section
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 Quick questions you can ask:")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• \"Which dependencies need updating?\"")
                    Text("• \"Are there critical vulnerabilities?\"")
                    Text("• \"What's the health of my project?\"")
                    Text("• \"Which updates are safe to apply?\"")
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("AI Chat") {
    let vm = AppViewModel()
    let project = Project(
        name: "MyApp",
        source: .manual,
        dependencies: [
            Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0", isOutdated: true)
        ]
    )
    
    return AIChatView(project: project, viewModel: vm)
}
