import SwiftUI

struct MainTabView: View {
    let viewModel: AppViewModel

    var body: some View {
        TabView {
            Tab("Pulse", systemImage: "waveform.path.ecg") {
                PulseView(viewModel: viewModel)
            }

            Tab("Stack", systemImage: "square.stack.3d.up.fill") {
                StackView(viewModel: viewModel)
            }

            Tab("Alerts", systemImage: "bell.badge.fill") {
                AlertsView(viewModel: viewModel)
            }
            .badge(viewModel.activeAlerts.count)

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView(viewModel: viewModel)
            }
        }
        .tint(Theme.accent)
        .task {
            if let lastSync = viewModel.lastSyncTime {
                let hourAgo = Date().addingTimeInterval(-3600)
                if lastSync < hourAgo {
                    await viewModel.syncStack()
                }
            } else if !viewModel.stackItems.isEmpty {
                await viewModel.syncStack()
            }
        }
    }
}
