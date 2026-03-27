import SwiftUI

struct TechnologyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AppViewModel
    let technology: Technology

    @State private var showVersionEditor = false
    @State private var newVersion = ""
    @State private var showDeleteConfirm = false
    @State private var isRegenerating = false
    @State private var showReleaseNotes = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    versionStatusSection
                    aiSummarySection
                    vulnerabilitiesSection
                    if technology.releaseNotes != nil {
                        releaseNotesSection
                    }
                    eolSection
                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Theme.background)
            .navigationTitle(technology.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    statusBadge
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .alert("Update Version", isPresented: $showVersionEditor) {
                TextField("Version (e.g. 18.3.1)", text: $newVersion)
                Button("Save") {
                    viewModel.updateVersion(for: technology.id, version: newVersion)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Remove Technology?", isPresented: $showDeleteConfirm) {
                Button("Remove", role: .destructive) {
                    viewModel.removeTechnology(technology)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove \(technology.name) from your stack.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: technology.status.icon)
                .font(.caption2)
            Text(technology.status.label)
                .font(.caption.bold())
        }
        .foregroundStyle(technology.status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(technology.status.color.opacity(0.12))
        .clipShape(.capsule)
    }

    private var versionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Version Status", systemImage: "tag")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    versionRow("Your Version", technology.currentVersion.isEmpty ? "Not set" : technology.currentVersion)
                    versionRow("Latest", technology.latestVersion.isEmpty ? "Unknown" : technology.latestVersion)
                }
                Spacer()

                if !technology.currentVersion.isEmpty && !technology.latestVersion.isEmpty && technology.currentVersion != technology.latestVersion {
                    let updateType = versionUpdateType
                    Text(updateType)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(updateType == "MAJOR" ? Theme.danger : updateType == "MINOR" ? Theme.warning : Theme.success)
                        .clipShape(.capsule)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var versionUpdateType: String {
        let current = technology.currentVersion.split(separator: ".").compactMap { Int($0) }
        let latest = technology.latestVersion.split(separator: ".").compactMap { Int($0) }
        guard let cMajor = current.first, let lMajor = latest.first else { return "UPDATE" }
        if lMajor > cMajor { return "MAJOR" }
        if latest.count > 1 && current.count > 1 && latest[1] > current[1] { return "MINOR" }
        return "PATCH"
    }

    private func versionRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var aiSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Summary", systemImage: "brain.head.profile.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if isRegenerating {
                    ProgressView()
                        .tint(Theme.accent)
                }
            }

            if let summary = technology.aiSummary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    let parts = summary.components(separatedBy: " · ")
                    ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: index == 0 ? "sparkles" : index == 1 ? "bolt.fill" : "wrench.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                                .frame(width: 16)
                            Text(part)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accent.opacity(0.06))
                .clipShape(.rect(cornerRadius: 8))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 3)
                        .clipShape(.rect(cornerRadius: 2))
                }
            } else {
                Text(viewModel.openAIKey.isEmpty ? "Add OpenAI key in Settings to enable AI summaries" : "No AI summary available yet. Sync to generate.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(12)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var vulnerabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Vulnerabilities", systemImage: "shield.lefthalf.filled")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if technology.vulnerabilities.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Theme.success)
                    Text("No known vulnerabilities")
                        .font(.subheadline)
                        .foregroundStyle(Theme.success)
                }
                .padding(12)
            } else {
                ForEach(technology.vulnerabilities) { vuln in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(vuln.id)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(vuln.severity.uppercased())
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(vuln.severity.lowercased().contains("high") || vuln.severity.lowercased().contains("critical") ? Theme.danger : Theme.warning)
                                .clipShape(.capsule)
                        }
                        Text(vuln.summary)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                        if let fixed = vuln.fixedVersion {
                            Text("Fixed in: v\(fixed)")
                                .font(.caption)
                                .foregroundStyle(Theme.success)
                        }
                    }
                    .padding(12)
                    .background(Theme.danger.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var releaseNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showReleaseNotes.toggle() }
            } label: {
                HStack {
                    Label("Release Notes", systemImage: "doc.text")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: showReleaseNotes ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if showReleaseNotes, let notes = technology.releaseNotes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(20)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.background)
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var eolSection: some View {
        Group {
            if let eolDate = technology.eolDate {
                VStack(alignment: .leading, spacing: 12) {
                    Label("End of Life", systemImage: "clock.badge.exclamationmark.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.warning)
                        Text("EOL: \(eolDate)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.warning.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 8))
                }
                .padding(16)
                .cardStyle()
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button {
                newVersion = technology.currentVersion
                showVersionEditor = true
            } label: {
                Label("Update My Version", systemImage: "pencil")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 10))
            }

            Button {
                showDeleteConfirm = true
            } label: {
                Label("Remove from Stack", systemImage: "trash")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.danger.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 10))
            }
        }
        .padding(16)
        .cardStyle()
    }
}
