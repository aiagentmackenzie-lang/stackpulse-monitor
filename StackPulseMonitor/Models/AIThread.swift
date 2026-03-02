import Foundation

/// Represents a chat conversation thread for a specific project
struct AIThread: Identifiable, Codable, Equatable {
    let id: UUID
    let projectId: UUID
    var messages: [AIMessage]
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    init(
        id: UUID = UUID(),
        projectId: UUID,
        messages: [AIMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.projectId = projectId
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
    
    /// Latest message preview for thread list
    var latestMessagePreview: String {
        guard let last = messages.last?.content else {
            return "New conversation"
        }
        return String(last.prefix(50))
    }
    
    /// Formatted date for display
    var lastActivityFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
    
    /// Unread messages count (simplified - all assistant messages since last user open)
    var hasNewMessages: Bool {
        guard let last = messages.last else { return false }
        return last.role == .assistant
    }
}

/// Represents a single message in a chat thread
struct AIMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: AIMessageRole
    var content: String
    var references: [String]?  // Dependency names mentioned
    var analysisRefs: [UUID]?    // References to AIAnalysisReport IDs
    let createdAt: Date
    var isStreaming: Bool       // For streaming responses
    
    init(
        id: UUID = UUID(),
        role: AIMessageRole,
        content: String,
        references: [String]? = nil,
        analysisRefs: [UUID]? = nil,
        createdAt: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.references = references
        self.analysisRefs = analysisRefs
        self.createdAt = createdAt
        self.isStreaming = isStreaming
    }
}

/// Message sender role
enum AIMessageRole: String, Codable {
    case user
    case assistant
    case system
}

/// Thread summary for list view
struct AIThreadSummary: Identifiable {
    let id: UUID
    let projectId: UUID
    let projectName: String
    let preview: String
    let lastActivity: String
    let hasNewMessages: Bool
    let messageCount: Int
}
