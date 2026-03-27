import Foundation

nonisolated enum AlertType: String, Codable, Sendable {
    case critical
    case update
    case eol
    case breaking
}

nonisolated struct TechAlert: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var techId: UUID
    var techName: String
    var type: AlertType
    var title: String
    var message: String
    var severity: String
    var createdAt: Date
    var isRead: Bool
    var readAt: Date?
    var isDismissed: Bool
    var snoozedUntil: Date?

    init(
        id: UUID = UUID(),
        techId: UUID,
        techName: String,
        type: AlertType,
        title: String,
        message: String,
        severity: String = "",
        createdAt: Date = Date(),
        isRead: Bool = false,
        readAt: Date? = nil,
        isDismissed: Bool = false,
        snoozedUntil: Date? = nil
    ) {
        self.id = id
        self.techId = techId
        self.techName = techName
        self.type = type
        self.title = title
        self.message = message
        self.severity = severity
        self.createdAt = createdAt
        self.isRead = isRead
        self.readAt = readAt
        self.isDismissed = isDismissed
        self.snoozedUntil = snoozedUntil
    }
}
