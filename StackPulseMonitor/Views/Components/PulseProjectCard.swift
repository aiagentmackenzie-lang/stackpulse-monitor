import SwiftUI

/// Card component displaying project summary with health score
struct PulseProjectCard: View {
    let project: Project
    let onTap: () -> Void
    
    /// Health score: percentage of dependencies that are up-to-date
    /// - Returns 0 if no dependencies have been checked (no latestVersion known)
    /// - Returns 0-100 based on up-to-date percentage
    private var healthScore: Int {
        let withKnownLatest = project.dependencies.filter { $0.latestVersion != nil }
        guard !withKnownLatest.isEmpty else { return 0 }
        
        let upToDate = withKnownLatest.filter { !$0.isOutdated }
        return Int((Double(upToDate.count) / Double(withKnownLatest.count)) * 100)
    }
    
    private var healthColor: Color {
        switch healthScore {
        case 0..<50: return .red
        case 50..<80: return .orange
        default: return .green
        }
    }
    
    private var checkedCount: Int {
        project.dependencies.filter { $0.latestVersion != nil }.count
    }
    
    private var outdatedCount: Int {
        project.outdatedCount
    }
    
    private var unknownCount: Int {
        project.dependencies.filter { $0.latestVersion == nil }.count
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Name + Health Score
                HStack {
                    // Project icon/name
                    HStack(spacing: 8) {
                        Image(systemName: project.isFromGitHub ? "folder.fill" : "doc.fill")
                            .foregroundStyle(Theme.accent)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            
                            if let fullName = project.githubFullName {
                                Text(fullName)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Health Score badge
                    HealthScoreBadge(score: healthScore, color: healthColor)
                }
                
                Divider()
                    .background(Theme.border)
                
                // Stats row
                HStack(spacing: 16) {
                    // Total deps
                    Label("\(project.dependencyCount)", systemImage: "shippingbox")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    
                    if outdatedCount > 0 {
                        Label("\(outdatedCount) outdated", systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                    
                    if unknownCount > 0 {
                        Label("\(unknownCount) unknown", systemImage: "questionmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                }
                
                // Last checked indicator
                if let lastChecked = project.dependencies.compactMap({ $0.lastChecked }).max() {
                    HStack {
                        Spacer()
                        Label("Checked \(timeAgo(from: lastChecked))", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: 0x1A1A1A))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Health Score Badge

struct HealthScoreBadge: View {
    let score: Int
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 48, height: 48)
            
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("%")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Preview

#Preview("Project Card - Various States") {
    VStack(spacing: 16) {
        // Healthy project
        PulseProjectCard(
            project: Project(
                name: "MyApp",
                source: .github,
                githubFullName: "raphael/myapp",
                dependencies: [
                    Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0", latestVersion: "18.2.0", isOutdated: false),
                    Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0", latestVersion: "4.18.0", isOutdated: false),
                    Dependency(name: "lodash", type: .npm, category: .backend, currentVersion: "4.17.21", latestVersion: "4.17.21", isOutdated: false)
                ]
            ),
            onTap: {}
        )
        
        // Warning state (some outdated)
        PulseProjectCard(
            project: Project(
                name: "LegacyAPI",
                source: .github,
                githubFullName: "raphael/legacy-api",
                dependencies: [
                    Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "17.0.0", latestVersion: "18.2.0", isOutdated: true),
                    Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0", latestVersion: "4.18.0", isOutdated: false),
                    Dependency(name: "lodash", type: .npm, category: .backend, currentVersion: "4.17.15", latestVersion: "4.17.21", isOutdated: true),
                    Dependency(name: "unknown", type: .npm, category: .other, currentVersion: "1.0.0", latestVersion: nil, isOutdated: false)
                ]
            ),
            onTap: {}
        )
        
        // Critical (mostly outdated)
        PulseProjectCard(
            project: Project(
                name: "OldProject",
                source: .manual,
                dependencies: [
                    Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "16.0.0", latestVersion: "18.2.0", isOutdated: true),
                    Dependency(name: "lodash", type: .npm, category: .backend, currentVersion: "4.15.0", latestVersion: "4.17.21", isOutdated: true)
                ]
            ),
            onTap: {}
        )
        
        // Unknown (nothing checked yet)
        PulseProjectCard(
            project: Project(
                name: "NewImport",
                source: .github,
                githubFullName: "raphael/new-import",
                dependencies: [
                    Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0", latestVersion: nil, isOutdated: false),
                    Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0", latestVersion: nil, isOutdated: false)
                ]
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Theme.background)
}
