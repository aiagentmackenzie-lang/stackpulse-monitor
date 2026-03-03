import SwiftUI

/// Reusable section for configuring alert notification preferences
struct AlertPreferencesSection: View {
    @ObservedObject var alertManager: AlertManager
    @State private var prefs: UserAlertPrefs
    
    init(alertManager: AlertManager = .shared) {
        self.alertManager = alertManager
        _prefs = State(initialValue: alertManager.prefs)
    }
    
    var body: some View {
        Section {
            // Master toggle
            Toggle("Enable Alert Notifications", isOn: $prefs.notificationsEnabled)
                .onChange(of: prefs.notificationsEnabled) { _, newValue in
                    if newValue {
                        Task {
                            await alertManager.requestPermission()
                        }
                    }
                    savePrefs()
                }
            
            if prefs.notificationsEnabled {
                // Alert type toggles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alert Types")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    
                    Toggle("Critical Vulnerabilities", isOn: $prefs.notifyForCritical)
                        .onChange(of: prefs.notifyForCritical) { _, _ in savePrefs() }
                    
                    Toggle("Version Updates", isOn: $prefs.notifyForUpdates)
                        .onChange(of: prefs.notifyForUpdates) { _, _ in savePrefs() }
                    
                    Toggle("End-of-Life Warnings", isOn: $prefs.notifyForEOL)
                        .onChange(of: prefs.notifyForEOL) { _, _ in savePrefs() }
                    
                    Toggle("Breaking Changes", isOn: $prefs.notifyForBreaking)
                        .onChange(of: prefs.notifyForBreaking) { _, _ in savePrefs() }
                }
                
                // Background refresh toggle
                Toggle("Background Refresh", isOn: $prefs.backgroundRefreshEnabled)
                    .onChange(of: prefs.backgroundRefreshEnabled) { _, _ in savePrefs() }
                
                // Quiet hours
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Quiet Hours", isOn: $prefs.quietHoursEnabled)
                        .onChange(of: prefs.quietHoursEnabled) { _, _ in savePrefs() }
                    
                    if prefs.quietHoursEnabled {
                        HStack {
                            DatePicker(
                                "Start",
                                selection: hourBinding(for: \.quietHoursStart),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            
                            Text("to")
                                .foregroundStyle(.secondary)
                            
                            DatePicker(
                                "End",
                                selection: hourBinding(for: \.quietHoursEnd),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }
                        .padding(.leading, 16)
                    }
                }
                .padding(.top, 8)
            }
        } header: {
            Label("Notifications", systemImage: "bell.badge.fill")
        } footer: {
            if prefs.notificationsEnabled {
                Text("Get notified when StackPulse finds vulnerabilities, updates, or EOL notices for your dependencies.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Enable notifications to stay informed about your stack health.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func savePrefs() {
        alertManager.updatePrefs(prefs)
    }
    
    /// Binding that converts hour integer to Date for DatePicker
    private func hourBinding(for keyPath: WritableKeyPath<UserAlertPrefs, Int>) -> Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = self.prefs[keyPath: keyPath]
                components.minute = 0
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let hour = Calendar.current.component(.hour, from: newDate)
                self.prefs[keyPath: keyPath] = hour
                self.savePrefs()
            }
        )
    }
}

// MARK: - Preview
#Preview {
    Form {
        AlertPreferencesSection()
    }
}
