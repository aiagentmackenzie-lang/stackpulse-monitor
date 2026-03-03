import SwiftUI
import UserNotifications

@main
struct StackPulseMonitorApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
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
