import Foundation

nonisolated enum TechType: String, Codable, Sendable, CaseIterable {
    case npm
    case github
    case language
    case platform
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
