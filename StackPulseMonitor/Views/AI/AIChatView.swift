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
                            }
                            
                            ForEach(thread.messages) { message in
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
        
        // Simulate AI response (will replace with OpenAI integration)
        isStreaming = true
        Task {
            // Small delay to simulate processing
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            let aiResponse = AIMessage(
                role: .assistant,
                content: generateAIResponse(to: messageText, project: project)
            )
            
            await MainActor.run {
                thread.messages.append(aiResponse)
                thread.updatedAt = Date()
                isStreaming = false
                saveThread()
            }
        }
    }
    
    private func generateAIResponse(to query: String, project: Project) -> String {
        // Simulation - will be replaced with OpenAI
        let lowerQuery = query.lowercased()
        
        if lowerQuery.contains("update") {
            let outdated = project.outdatedCount
            if outdated > 0 {
                return "📦 You have \(outdated) outdated \(outdated == 1 ? "dependency" : "dependencies") in \(project.name).\n\nWould you like me to analyze which ones are safe to update?"
            } else {
                return "✅ All dependencies in \(project.name) are up to date!"
            }
        } else if lowerQuery.contains("critical") || lowerQuery.contains("security") {
            return "🔒 Currently scanning for critical vulnerabilities...\n\n(This feature will be fully available once OpenAI integration is complete)"
        } else if lowerQuery.contains("hello") || lowerQuery.contains("hi") {
            return "👋 Hello! I'm your AI assistant for \(project.name).\n\nI can help you:\n• Analyze dependencies\n• Check for vulnerabilities\n• Recommend updates\n• Explain breaking changes\n\nWhat would you like to know?"
        } else if lowerQuery.contains("dependency") || lowerQuery.contains("deps") {
            return "📊 \(project.name) has \(project.dependencyCount) dependencies.\n\n• \(project.outdatedCount) need updates\n• Recent analysis available in the Reports tab\n\nAsk me about specific dependencies!"
        } else {
            return "💡 I'm here to help with dependency analysis for \(project.name).\n\nTry asking:\n• \"Which dependencies need updating?\"\n• \"Are there any critical vulnerabilities?\"\n• \"What does [dependency] do?\""
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
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.purple)
            
            Text("Ask me anything about \(project.name)")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Try asking:")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("• \"Which dependencies need updating?\"")
                    Text("• \"Are there critical vulnerabilities?\"")
                    Text("• \"What does React 19 change?\"")
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 32)
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
