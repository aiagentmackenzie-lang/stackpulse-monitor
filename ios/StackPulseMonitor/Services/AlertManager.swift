import Foundation
import UserNotifications
import Combine
import UIKit

/// Manages alert detection, persistence, and notification scheduling
@MainActor
final class AlertManager: ObservableObject {
    static let shared = AlertManager()

    private let storage: StorageService
    private let notificationCenter: UNUserNotificationCenter

    @Published private(set) var prefs: UserAlertPrefs
    @Published private(set) var hasPermission: Bool = false

    private init(
        storage: StorageService = .shared,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.storage = storage
        self.notificationCenter = notificationCenter
        self.prefs = storage.loadAlertPrefs() ?? .default
    }

    // MARK: - Permissions

    /// Request notification permissions from user
    func requestPermission() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            hasPermission = granted
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            hasPermission = false
            return false
        }
    }

    /// Check current notification permission status
    func checkPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        hasPermission = settings.authorizationStatus == .authorized
    }

    // MARK: - Alert Processing

    private var currentProjectId: UUID? = nil

    /// Process new alerts and schedule notifications if appropriate
    func processAlerts(_ alerts: [TechAlert], forProject projectId: UUID? = nil) {
        guard prefs.notificationsEnabled, hasPermission else { return }
        
        // Store projectId for notification payload
        self.currentProjectId = projectId

        for alert in alerts {
            guard shouldNotify(alert: alert, projectId: projectId) else { continue }

            // Check quiet hours
            if prefs.quietHoursEnabled && isInQuietHours() {
                scheduleNotificationForLater(alert)
            } else {
                scheduleNotification(alert)
            }
        }
        
        // Clear after processing
        self.currentProjectId = nil
    }

    /// Determine if an alert should trigger a notification
    func shouldNotify(alert: TechAlert, projectId: UUID? = nil) -> Bool {
        // Check global notification setting
        guard prefs.notificationsEnabled else { return false }

        // Check alert type preference
        switch alert.type {
        case .critical:
            guard prefs.notifyForCritical else { return false }
        case .update:
            guard prefs.notifyForUpdates else { return false }
        case .eol:
            guard prefs.notifyForEOL else { return false }
        case .breaking:
            guard prefs.notifyForBreaking else { return false }
        }

        // Check project-specific settings if applicable
        if let projectId = projectId,
           let projectSettings = prefs.projectSpecificSettings[projectId] {
            guard projectSettings.enabled else { return false }

            switch alert.type {
            case .critical:
                guard projectSettings.notifyForCritical else { return false }
            case .update:
                guard projectSettings.notifyForUpdates else { return false }
            case .eol:
                guard projectSettings.notifyForEOL else { return false }
            case .breaking:
                guard projectSettings.notifyForBreaking else { return false }
            }
        }

        return true
    }

    // MARK: - Notification Scheduling

    private func scheduleNotification(_ alert: TechAlert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ALERT"

        // Add custom data for deep linking
        var userInfo: [String: String] = [
            "alertId": alert.id.uuidString,
            "techId": alert.techId.uuidString,
            "type": alert.type.rawValue
        ]
        if let projectId = currentProjectId {
            userInfo["projectId"] = projectId.uuidString
        }
        content.userInfo = userInfo

        // Immediate notification
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil // Immediate
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func scheduleNotificationForLater(_ alert: TechAlert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ALERT"
        
        // Add custom data for deep linking
        var userInfo: [String: String] = [
            "alertId": alert.id.uuidString,
            "techId": alert.techId.uuidString,
            "type": alert.type.rawValue
        ]
        if let projectId = currentProjectId {
            userInfo["projectId"] = projectId.uuidString
        }
        content.userInfo = userInfo

        // Schedule after quiet hours end
        var dateComponents = DateComponents()
        dateComponents.hour = prefs.quietHoursEnd
        dateComponents.minute = 0

        // If quiet hours end is tomorrow, add a day
        let now = Calendar.current.component(.hour, from: Date())
        if prefs.quietHoursEnd <= now {
            // Schedule for tomorrow
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            dateComponents.day = Calendar.current.component(.day, from: tomorrow)
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule delayed notification: \(error)")
            }
        }
    }

    // MARK: - Background Refresh

    /// Check if background refresh is available and enabled
    func isBackgroundRefreshAvailable() -> Bool {
        return prefs.backgroundRefreshEnabled && UIApplication.shared.backgroundRefreshStatus == .available
    }

    /// Called when background refresh occurs
    func performBackgroundCheck(alerts: [TechAlert]) {
        guard isBackgroundRefreshAvailable() else { return }
        processAlerts(alerts)
    }

    // MARK: - Preferences Management

    func updatePrefs(_ newPrefs: UserAlertPrefs) {
        prefs = newPrefs
        storage.saveAlertPrefs(newPrefs)
    }

    func updateProjectSettings(projectId: UUID, settings: ProjectAlertSettings) {
        prefs.projectSpecificSettings[projectId] = settings
        storage.saveAlertPrefs(prefs)
    }

    func resetProjectSettings(projectId: UUID) {
        prefs.projectSpecificSettings.removeValue(forKey: projectId)
        storage.saveAlertPrefs(prefs)
    }

    // MARK: - Helpers

    private func isInQuietHours() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())

        if prefs.quietHoursStart < prefs.quietHoursEnd {
            // Simple range (e.g., 22:00 - 08:00)
            return hour >= prefs.quietHoursStart && hour < prefs.quietHoursEnd
        } else {
            // Wrapped range (e.g., 22:00 - 08:00 crosses midnight)
            return hour >= prefs.quietHoursStart || hour < prefs.quietHoursEnd
        }
    }

    // MARK: - Notification Management

    /// Remove a scheduled notification
    func cancelNotification(for alertId: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [alertId.uuidString])
        // Also remove if already delivered
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [alertId.uuidString])
    }

    /// Remove all scheduled notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        // Also clear all delivered notifications
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Clear badge count
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - UIApplication Extension for Background Status
import UIKit

extension UIApplication {
    var backgroundRefreshStatus: UIBackgroundRefreshStatus {
        return UIApplication.shared.backgroundRefreshStatus
    }
}
