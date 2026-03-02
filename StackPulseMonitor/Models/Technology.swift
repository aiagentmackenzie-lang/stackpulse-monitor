import Foundation

// MARK: - Project-Centric Data Model

/// A project imported from GitHub or created manually
struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var source: ProjectSource
    var githubFullName: String?
    var importedAt: Date
    var isExpanded: Bool = true
    var dependencies: [Dependency] = []
    var aiReports: [ProjectAIReport] = []  // Persisted AI analyses
    var aiThreads: [AIThread] = []         // NEW: Chat threads per project
    
    init(
        id: UUID = UUID(),
        name: String,
        source: ProjectSource,
        githubFullName: String? = nil,
        importedAt: Date = Date(),
        isExpanded: Bool = true,
        dependencies: [Dependency] = [],
        aiReports: [ProjectAIReport] = [],
        aiThreads: [AIThread] = []
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.githubFullName = githubFullName
        self.importedAt = importedAt
        self.isExpanded = isExpanded
        self.dependencies = dependencies
        self.aiReports = aiReports
        self.aiThreads = aiThreads
    }
    
    var dependencyCount: Int { dependencies.count }
    var outdatedCount: Int { dependencies.filter { $0.isOutdated }.count }
    var isFromGitHub: Bool { source == .github }
}

enum ProjectSource: String, Codable, CaseIterable {
    case github = "GitHub"
    case manual = "Manual"
}

/// A dependency within a project
struct Dependency: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: TechType
    var category: TechCategory
    var currentVersion: String
    var latestVersion: String?
    var lastChecked: Date?
    var isOutdated: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        type: TechType,
        category: TechCategory,
        currentVersion: String,
        latestVersion: String? = nil,
        lastChecked: Date? = nil,
        isOutdated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.lastChecked = lastChecked
        self.isOutdated = isOutdated
    }
    
    var identifier: String { "\(type.rawValue):\(name)" }
}

// MARK: - Technology Types

/// Technology ecosystem types for dependency classification
nonisolated enum TechType: String, Codable, Sendable, CaseIterable {
    // Package registries
    case npm          // Node.js / JavaScript
    case pypi         // Python
    case cargo        // Rust
    case gomod        // Go modules
    case maven        // Java (Maven)
    case gradle       // Java (Gradle)
    case gem          // Ruby
    case composer     // PHP
    
    // Other sources
    case github       // GitHub repositories
    case language     // Programming languages
    case platform     // Services (AWS, Vercel, etc.)
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .npm: return "NPM"
        case .pypi: return "PyPI"
        case .cargo: return "Cargo"
        case .gomod: return "Go"
        case .maven: return "Maven"
        case .gradle: return "Gradle"
        case .gem: return "RubyGems"
        case .composer: return "Composer"
        case .github: return "GitHub"
        case .language: return "Language"
        case .platform: return "Platform"
        }
    }
    
    /// Icon name for UI
    var iconName: String {
        switch self {
        case .npm: return "shippingbox"
        case .pypi: return "arrow.down.circle"
        case .cargo: return "shippingbox.fill"
        case .gomod: return "g.circle"
        case .maven: return "m.circle"
        case .gradle: return "g.square"
        case .gem: return "diamond"
        case .composer: return "c.circle"
        case .github: return "logo.github"
        case .language: return "chevron.left.forwardslash.chevron.right"
        case .platform: return "cloud"
        }
    }
}

nonisolated enum TechCategory: String, Codable, Sendable, CaseIterable {
    case frontend = "Frontend"
    case backend = "Backend"
    case database = "Database"
    case devops = "DevOps"
    case language = "Language"
    case other = "Other"
}

nonisolated enum TechStatus: String, Codable, Sendable {
    case ok
    case update
    case critical
    case eol
    case unknown
}

nonisolated struct Technology: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var name: String
    var type: TechType
    var identifier: String
    var category: TechCategory
    var currentVersion: String
    var latestVersion: String
    var status: TechStatus
    var lastChecked: Date?
    var aiSummary: String?
    var vulnerabilities: [Vulnerability]
    var releaseNotes: String?
    var eolDate: String?
    var breaking: Bool

    init(
        id: UUID = UUID(),
        name: String,
        type: TechType = .npm,
        identifier: String = "",
        category: TechCategory = .other,
        currentVersion: String = "",
        latestVersion: String = "",
        status: TechStatus = .unknown,
        lastChecked: Date? = nil,
        aiSummary: String? = nil,
        vulnerabilities: [Vulnerability] = [],
        releaseNotes: String? = nil,
        eolDate: String? = nil,
        breaking: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.identifier = identifier
        self.category = category
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.status = status
        self.lastChecked = lastChecked
        self.aiSummary = aiSummary
        self.vulnerabilities = vulnerabilities
        self.releaseNotes = releaseNotes
        self.eolDate = eolDate
        self.breaking = breaking
    }
}

nonisolated struct Vulnerability: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var summary: String
    var severity: String
    var publishedDate: String?
    var fixedVersion: String?
}

// MARK: - Project AI Thread Helpers

extension Project {
    /// Get or create the primary AI thread for this project
    mutating func getOrCreateThread() -> AIThread {
        if let existing = aiThreads.first(where: { !$0.isDeleted }) {
            return existing
        }
        let newThread = AIThread(projectId: id)
        aiThreads.append(newThread)
        return newThread
    }
    
    /// Add a message to the primary thread
    mutating func addMessage(_ message: AIMessage) {
        if let index = aiThreads.firstIndex(where: { !$0.isDeleted }) {
            aiThreads[index].messages.append(message)
            aiThreads[index].updatedAt = Date()
        } else {
            var thread = getOrCreateThread()
            thread.messages.append(message)
            thread.updatedAt = Date()
            aiThreads.append(thread)
        }
    }
    
    /// Delete a specific thread
    mutating func deleteThread(_ threadId: UUID) {
        if let index = aiThreads.firstIndex(where: { $0.id == threadId }) {
            aiThreads[index].isDeleted = true
        }
    }
    
    /// All active (non-deleted) threads
    var activeThreads: [AIThread] {
        aiThreads.filter { !$0.isDeleted }
    }
    
    /// Primary thread summary for list view
    var threadSummary: AIThreadSummary? {
        guard let thread = activeThreads.first else { return nil }
        return AIThreadSummary(
            id: thread.id,
            projectId: id,
            projectName: name,
            preview: thread.latestMessagePreview,
            lastActivity: thread.lastActivityFormatted,
            hasNewMessages: thread.hasNewMessages,
            messageCount: thread.messages.count
        )
    }
}
