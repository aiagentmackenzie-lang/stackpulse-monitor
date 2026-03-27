import SwiftUI
import UserNotifications
import Combine

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()
    
    @Published var selectedProjectId: UUID?
    @Published var selectedAlertId: UUID?
    
    private override init() {}
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract IDs from notification payload
        if let projectIdString = userInfo["projectId"] as? String,
           let projectId = UUID(uuidString: projectIdString) {
            selectedProjectId = projectId
        }
        
        if let alertIdString = userInfo["alertId"] as? String,
           let alertId = UUID(uuidString: alertIdString) {
            selectedAlertId = alertId
        }
        
        completionHandler()
    }
}

@main
struct StackPulseMonitorApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var notificationDelegate = NotificationDelegate.shared
    
    init() {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
                .onChange(of: notificationDelegate.selectedProjectId) { _, projectId in
                    // Handle deep link from notification tap
                    if let projectId = projectId {
                        // Navigation will be handled by ContentView observing this
                        NotificationCenter.default.post(
                            name: .init("NavigateToProject"),
                            object: projectId
                        )
                        // Reset after handling
                        notificationDelegate.selectedProjectId = nil
                    }
                }
        }
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active - clear notification badge
            UNUserNotificationCenter.current().setBadgeCount(0)
        case .background:
            // App went to background - could trigger background refresh check here
            break
        default:
            break
        }
    }
}
