import SwiftUI

struct SettingsView: View {
    let viewModel: AppViewModel
    @State private var showAPIKeyEditor = false
    @State private var showClearConfirm = false
    @State private var apiKeyInput = ""
    @State private var isTesting = false
    @State private var testSuccess: Bool?
    @State private var autoSync = true
    @State private var syncOnOpen = true
    @State private var criticalAlerts = true
    @State private var updateAlerts = true
    @State private var eolAlerts = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("OpenAI API Key")
                                    .foregroundStyle(Theme.textPrimary)
                                Text(viewModel.openAIKey.isEmpty ? "Not configured" : maskedKey)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "key.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        Spacer()
                        Button(viewModel.openAIKey.isEmpty ? "Add" : "Edit") {
                            apiKeyInput = viewModel.openAIKey
                            showAPIKeyEditor = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                    }
                    .listRowBackground(Theme.cardBackground)
                } header: {
                    Text("AI Configuration")
                        .foregroundStyle(Theme.textSecondary)
                }

                Section {
                    Button {
                        Task { await viewModel.syncStack() }
                    } label: {
                        Label {
                            HStack {
                                Text("Sync Now")
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if viewModel.isSyncing {
                                    ProgressView()
                                        .tint(Theme.accent)
                                }
                            }
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .disabled(viewModel.isSyncing)
                    .listRowBackground(Theme.cardBackground)

                    if let lastSync = viewModel.lastSyncTime {
                        HStack {
                            Label("Last Sync", systemImage: "clock")
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(lastSync.relativeString)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .listRowBackground(Theme.cardBackground)
                    }
                } header: {
                    Text("Sync")
                        .foregroundStyle(Theme.textSecondary)
                }

                Section {
                    Toggle(isOn: $criticalAlerts) {
                        Label("Critical CVE Alerts", systemImage: "shield.exclamationmark.fill")
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.cardBackground)

                    Toggle(isOn: $updateAlerts) {
                        Label("Major Updates", systemImage: "arrow.up.circle.fill")
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.cardBackground)

                    Toggle(isOn: $eolAlerts) {
                        Label("EOL Warnings", systemImage: "clock.badge.exclamationmark.fill")
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.cardBackground)
                } header: {
                    Text("Notifications")
                        .foregroundStyle(Theme.textSecondary)
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundStyle(Theme.danger)
                    }
                    .listRowBackground(Theme.cardBackground)
                } header: {
                    Text("Data")
                        .foregroundStyle(Theme.textSecondary)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(Theme.accent)
                            Text("STACKPULSE")
                                .font(.headline.bold())
                                .foregroundStyle(Theme.textPrimary)
                                .tracking(1)
                        }
                        Text("v1.0.0")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Built by Raphael Main")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Data: NPM Registry · GitHub API · OSV.dev · endoflife.date")
                            .font(.caption2)
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Theme.cardBackground)
                } header: {
                    Text("About")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .toolbarBackground(Theme.background, for: .navigationBar)
            .alert("Edit API Key", isPresented: $showAPIKeyEditor) {
                SecureField("sk-proj-...", text: $apiKeyInput)
                Button("Save") {
                    viewModel.saveOpenAIKey(apiKeyInput)
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Clear All Data?", isPresented: $showClearConfirm) {
                Button("Clear Everything", role: .destructive) {
                    viewModel.clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove your entire stack, alerts, and API key. This cannot be undone.")
            }
        }
    }

    private var maskedKey: String {
        let key = viewModel.openAIKey
        guard key.count > 8 else { return "••••••••" }
        return String(key.prefix(7)) + "••••" + String(key.suffix(4))
    }
}
