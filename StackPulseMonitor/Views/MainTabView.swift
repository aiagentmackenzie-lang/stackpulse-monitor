import SwiftUI

struct MainTabView: View {
    let viewModel: AppViewModel

    var body: some View {
        TabView {
            Tab("Pulse", systemImage: "waveform.path.ecg") {
                PulseView(viewModel: viewModel)
            }

            Tab("Projects", systemImage: "folder.fill") {
                NavigationStack {
                    ProjectListView(viewModel: viewModel)
                }
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
    }
}
