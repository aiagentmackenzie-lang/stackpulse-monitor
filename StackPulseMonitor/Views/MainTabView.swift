import SwiftUI

struct MainTabView: View {
    let viewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAISheet = false
    @State private var selectedTab = 0  // Track active tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Pulse", systemImage: "waveform.path.ecg", value: 0) {
                PulseView(viewModel: viewModel)
            }

            Tab("Projects", systemImage: "folder.fill", value: 1) {
                NavigationStack {
                    ProjectListView(viewModel: viewModel)
                }
            }

            // AI Tab (center, prominent) - Purple icon
            Tab(value: 2) {
                EmptyView()
            } label: {
                Label("AI", systemImage: "sparkles")
                    .foregroundStyle(.purple)
            }

            Tab("Alerts", systemImage: "bell.badge.fill", value: 3) {
                AlertsView(viewModel: viewModel)
            }
            .badge(viewModel.activeAlerts.count)

            Tab("Settings", systemImage: "gearshape.fill", value: 4) {
                SettingsView(viewModel: viewModel)
            }
        }
        .tint(Theme.accent)
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == 2 {
                // AI tab tapped - show sheet and revert
                showAISheet = true
                selectedTab = oldTab  // Go back to previous tab
            }
        }
        .sheet(isPresented: $showAISheet) {
            AIActionMenuSheet(viewModel: viewModel)
        }
        // FIXME: .onChange API needs iOS version fix
        // .onChange(of: scenePhase) { newPhase in
        //     if newPhase == .active {
        //         viewModel.refreshAlerts()
        //     }
        // }
    }
}

// MARK: - AI Button

struct AIButton: View {
    let viewModel: AppViewModel
    @State private var showMenu = false
    
    var body: some View {
        Button {
            showMenu = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                Text("AI")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.purple)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.purple.opacity(0.15))
            .clipShape(.rect(cornerRadius: 8))
        }
        .sheet(isPresented: $showMenu) {
            AIActionMenuSheet(viewModel: viewModel)
        }
    }
}

// MARK: - AI Action Menu Sheet

struct AIActionMenuSheet: View {
    let viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProject: Project?
    @State private var showMultiProjectAnalysis = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(.purple)
                        
                        Text("AI Assistant")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        
                        Text("Smart analysis for your dependencies")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        if hasOutdatedDeps {
                            // All Projects Analysis
                            AIActionCard(
                                icon: "chart.bar.fill",
                                iconColor: .purple,
                                title: "Analyze All Projects",
                                subtitle: outdatedSummary,
                                action: {
                                    dismiss()
                                    showMultiProjectAnalysis = true
                                }
                            )
                        }
                        
                        // Specific Project
                        AIActionCard(
                            icon: "folder.fill",
                            iconColor: .blue,
                            title: "Analyze Specific Project",
                            subtitle: "Get insights on one project",
                            action: {
                                // Show project picker in Pulse tab
                                dismiss()
                                // Navigate to Pulse tab
                                NotificationCenter.default.post(name: .switchToPulseTab, object: nil)
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showMultiProjectAnalysis) {
                if #available(iOS 16.0, *) {
                    MultiProjectAIAnalysisView(viewModel: viewModel)
                } else {
                    Text("AI Analysis requires iOS 16+")
                }
            }
        }
    }
    
    private var hasOutdatedDeps: Bool {
        viewModel.projects.contains { $0.outdatedCount > 0 }
    }
    
    private var outdatedSummary: String {
        let totalOutdated = viewModel.projects.reduce(0) { $0 + $1.outdatedCount }
        let projectCount = viewModel.projects.filter { $0.outdatedCount > 0 }.count
        return "\(totalOutdated) updates across \(projectCount) \(projectCount == 1 ? "project" : "projects")"
    }
}

// MARK: - AI Action Card

struct AIActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.muted)
            }
            .padding(16)
            .background(Color(hex: 0x1A1A1A))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let switchToPulseTab = Notification.Name("switchToPulseTab")
}
