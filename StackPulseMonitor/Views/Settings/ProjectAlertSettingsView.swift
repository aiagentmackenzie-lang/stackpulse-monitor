import SwiftUI

/// Per-project alert customization settings
struct ProjectAlertSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let project: Project
    @ObservedObject var alertManager: AlertManager
    
    @State private var useGlobalSettings: Bool = true
    @State private var projectSettings: ProjectAlertSettings = .default
    
    init(project: Project, alertManager: AlertManager = .shared) {
        self.project = project
        self.alertManager = alertManager
        
        // Check if project has custom settings
        if let existingSettings = alertManager.prefs.projectSpecificSettings[project.id] {
            _useGlobalSettings = State(initialValue: false)
            _projectSettings = State(initialValue: existingSettings)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Global settings toggle
                Section {
                    Toggle("Use Global Settings", isOn: $useGlobalSettings)
                        .onChange(of: useGlobalSettings) { _, newValue in
                            if newValue {
                                // Remove custom settings
                                alertManager.resetProjectSettings(projectId: project.id)
                            } else {
                                // Apply custom settings
                                alertManager.updateProjectSettings(projectId: project.id, settings: projectSettings)
                            }
                        }
                } footer: {
                    if useGlobalSettings {
                        Text("This project will use your global notification preferences.")
                            .font(.caption)
                    }
                }
                
                if !useGlobalSettings {
                    // Project-specific settings
                    Section("Project-Specific Alerts") {
                        Toggle("Enabled", isOn: $projectSettings.enabled)
                            .onChange(of: projectSettings.enabled) { _, _ in saveSettings() }
                        
                        if projectSettings.enabled {
                            Divider()
                            
                            Toggle("Critical Vulnerabilities", isOn: $projectSettings.notifyForCritical)
                                .onChange(of: projectSettings.notifyForCritical) { _, _ in saveSettings() }
                            
                            Toggle("Version Updates", isOn: $projectSettings.notifyForUpdates)
                                .onChange(of: projectSettings.notifyForUpdates) { _, _ in saveSettings() }
                            
                            Toggle("End-of-Life Warnings", isOn: $projectSettings.notifyForEOL)
                                .onChange(of: projectSettings.notifyForEOL) { _, _ in saveSettings() }
                            
                            Toggle("Breaking Changes", isOn: $projectSettings.notifyForBreaking)
                                .onChange(of: projectSettings.notifyForBreaking) { _, _ in saveSettings() }
                        }
                    }
                }
                
                // Info section
                Section {
                    EmptyView()
                } header: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Project: \(project.name)")
                    }
                } footer: {
                    if useGlobalSettings {
                        Text("Global settings: Critical \(alertManager.prefs.notifyForCritical ? "✓" : "✗"), Updates \(alertManager.prefs.notifyForUpdates ? "✓" : "✗"), EOL \(alertManager.prefs.notifyForEOL ? "✓" : "✗"), Breaking \(alertManager.prefs.notifyForBreaking ? "✓" : "✗")")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Alert Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        if !useGlobalSettings {
            alertManager.updateProjectSettings(projectId: project.id, settings: projectSettings)
        }
    }
}

// MARK: - Preview
#Preview {
    let project = Project(name: "Test Project", source: .manual)
    ProjectAlertSettingsView(project: project)
}
