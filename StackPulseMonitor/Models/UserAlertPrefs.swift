import Foundation

/// User preferences for alert notifications
struct UserAlertPrefs: Codable, Sendable {
    // MARK: - Global Settings
    var notificationsEnabled: Bool
    var backgroundRefreshEnabled: Bool
    
    // MARK: - Alert Type Toggles
    var notifyForCritical: Bool
    var notifyForUpdates: Bool
    var notifyForEOL: Bool
    var notifyForBreaking: Bool
    
    // MARK: - Per-Project Settings
    var projectSpecificSettings: [UUID: ProjectAlertSettings]
    
    // MARK: - Scheduling
    var quietHoursEnabled: Bool
    var quietHoursStart: Int // Hour (0-23)
    var quietHoursEnd: Int // Hour (0-23)
    
    // MARK: - Defaults
    static let `default` = UserAlertPrefs(
        notificationsEnabled: true,
        backgroundRefreshEnabled: true,
        notifyForCritical: true,
        notifyForUpdates: true,
        notifyForEOL: false,
        notifyForBreaking: true,
        projectSpecificSettings: [:],
        quietHoursEnabled: false,
        quietHoursStart: 22,
        quietHoursEnd: 8
    )
}

/// Per-project alert settings
struct ProjectAlertSettings: Codable, Sendable {
    var enabled: Bool
    var notifyForCritical: Bool
    var notifyForUpdates: Bool
    var notifyForEOL: Bool
    var notifyForBreaking: Bool
    
    static let `default` = ProjectAlertSettings(
        enabled: true,
        notifyForCritical: true,
        notifyForUpdates: true,
        notifyForEOL: false,
        notifyForBreaking: true
    )
}
