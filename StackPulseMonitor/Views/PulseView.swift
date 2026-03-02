import SwiftUI

struct PulseView: View {
    let viewModel: AppViewModel
    @State private var selectedTech: Technology?
    @State private var isCheckingVersions = false
    @State private var checkProgress = ""
    @State private var lastCheckTime: Date?
    
    /// Flatten all dependencies from all projects
    private var allDependencies: [Technology] {
        viewModel.projects.flatMap { project in
            project.dependencies.map { dep in
                Technology(
                    name: dep.name,
                    type: dep.type,
                    identifier: dep.identifier,
                    category: dep.category,
                    currentVersion: dep.currentVersion,
                    latestVersion: dep.latestVersion ?? ""
                )
            }
        }
    }
    
    /// Dependencies with known versions
    private var checkedDependencies: [Technology] {
        allDependencies.filter { !$0.latestVersion.isEmpty }
    }
    
    /// Outdated count
    private var outdatedCount: Int {
        checkedDependencies.filter { tech in
            VersionChecker.isOutdated(current: tech.currentVersion, latest: tech.latestVersion)
        }.count
    }
    
    /// Health score (only for checked deps)
    private var healthScore: Int? {
        let checked = checkedDependencies
        guard !checked.isEmpty else { return nil }
        let upToDate = checked.count - outdatedCount
        return Int((Double(upToDate) / Double(checked.count)) * 100)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Health Score Card
                    HealthScoreCard(
                        score: healthScore,
                        totalDeps: allDependencies.count,
                        checkedCount: checkedDependencies.count,
                        outdatedCount: outdatedCount,
                        lastCheckTime: lastCheckTime,
                        isChecking: isCheckingVersions,
                        progress: checkProgress,
                        onCheck: checkVersions
                    )
                    
                    // Dependencies List
                    LazyVStack(spacing: 12) {
                        ForEach(allDependencies) { tech in
                            Button {
                                selectedTech = tech
                            } label: {
                                techStatusCard(tech)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Pulse")
            .sheet(item: $selectedTech) { tech in
                TechnologyDetailView(viewModel: viewModel, technology: tech)
            }
            .onAppear {
                // Load last check time from persistence if available
            }
        }
    }
    
    private func checkVersions() {
        Task {
            isCheckingVersions = true
            checkProgress = "Preparing..."
            
            // Collect all dependencies from all projects
            var allDeps: [Dependency] = []
            var projectMap: [UUID: UUID] = [:] // depID -> projectID
            
            for project in viewModel.projects {
                for dep in project.dependencies where dep.latestVersion == nil {
                    allDeps.append(dep)
                    projectMap[dep.id] = project.id
                }
            }
            
            guard !allDeps.isEmpty else {
                checkProgress = "All dependencies checked"
                try? await Task.sleep(nanoseconds: 500_000_000)
                isCheckingVersions = false
                lastCheckTime = Date()
                return
            }
            
            // Check versions
            let results = await VersionCheckService.shared.checkVersions(allDeps)
            
            // Update dependencies
            await MainActor.run {
                for (depId, latestVersion) in results {
                    guard let projectId = projectMap[depId],
                          let projectIndex = viewModel.projects.firstIndex(where: { $0.id == projectId }),
                          let depIndex = viewModel.projects[projectIndex].dependencies.firstIndex(where: { $0.id == depId }) else { continue }
                    
                    viewModel.projects[projectIndex].dependencies[depIndex].latestVersion = latestVersion
                    let current = viewModel.projects[projectIndex].dependencies[depIndex].currentVersion
                    viewModel.projects[projectIndex].dependencies[depIndex].isOutdated = VersionChecker.isOutdated(current: current, latest: latestVersion)
                }
                
                // Save updated projects
                viewModel.persistProjects()
            }
            
            checkProgress = "Done"
            try? await Task.sleep(nanoseconds: 500_000_000)
            isCheckingVersions = false
            lastCheckTime = Date()
        }
    }
}

// MARK: - Health Score Card

struct HealthScoreCard: View {
    let score: Int?
    let totalDeps: Int
    let checkedCount: Int
    let outdatedCount: Int
    let lastCheckTime: Date?
    let isChecking: Bool
    let progress: String
    let onCheck: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Score display
            HStack(spacing: 12) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    if let score = score {
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(score)%")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(score >= 90 ? "Good" : score >= 70 ? "Fair" : "Needs Attention")
                                .font(.caption2)
                                .foregroundStyle(scoreColor)
                        }
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundStyle(Theme.textSecondary)
                            Text("?")
                                .font(.title3)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if score == nil {
                        Text("Health Score Unknown")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        
                        Text("\(totalDeps) dependencies need checking")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("Health Score: \(score!)%")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        
                        if outdatedCount > 0 {
                            Text("\(outdatedCount) of \(checkedCount) outdated")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        } else {
                            Text("All \(checkedCount) dependencies up to date")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    if let lastCheck = lastCheckTime {
                        Text("Last checked: \(formatTimeSince(lastCheck))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                Spacer()
            }
            
            // Check button
            Button(action: onCheck) {
                HStack {
                    if isChecking {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                        Text(progress)
                            .font(.subheadline.weight(.semibold))
                    } else {
                        Image(systemName: "arrow.clockwise")
                        Text(score == nil ? "Check Dependencies" : "Check for Updates")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isChecking ? Theme.muted : Theme.accent)
                .clipShape(.rect(cornerRadius: 10))
            }
            .disabled(isChecking)
        }
        .padding(16)
        .background(Color(hex: 0x1A1A1A))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var scoreColor: Color {
        guard let score = score else { return .gray }
        if score >= 90 { return .green }
        if score >= 70 { return .orange }
        return .red
    }
    
    private func formatTimeSince(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Tech Status Card

extension PulseView {
    func techStatusCard(_ tech: Technology) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconForType(tech.type))
                .font(.title3)
                .foregroundStyle(categoryColor(tech.category))
                .frame(width: 40)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tech.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                
                HStack(spacing: 8) {
                    Text(tech.currentVersion)
                        .foregroundStyle(Theme.textSecondary)

                    if !tech.latestVersion.isEmpty && tech.latestVersion != tech.currentVersion {
                        Image(systemName: "arrow.forward")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(tech.latestVersion)
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
            }
            
            Spacer()
            
            // Status indicator
            if !tech.latestVersion.isEmpty {
                if VersionChecker.isOutdated(current: tech.currentVersion, latest: tech.latestVersion) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                }
            } else {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.gray)
                    .font(.callout)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0x1A1A1A))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func categoryColor(_ category: TechCategory) -> Color {
        switch category {
        case .frontend: return .blue
        case .backend: return .green
        case .database: return .orange
        case .devops: return .purple
        case .language: return .cyan
        case .other: return .gray
        }
    }

    private func iconForType(_ type: TechType) -> String {
        switch type {
        case .npm: return "shippingbox.fill"
        case .pypi: return "leaf.fill"
        case .cargo: return "cube.fill"
        case .gomod: return "g.circle.fill"
        case .maven, .gradle: return "j.circle.fill"
        case .gem: return "diamond.fill"
        case .composer: return "c.circle.fill"
        case .github: return "logo.github"
        case .language: return "chevron.left.forwardslash.chevron.right"
        case .platform: return "cloud.fill"
        }
    }
}

// MARK: - Version Checker

enum VersionChecker {
    /// Compares two semantic versions
    static func isOutdated(current: String, latest: String) -> Bool {
        let currentParts = current
            .replacingOccurrences(of: "^", with: "")
            .replacingOccurrences(of: "~", with: "")
            .replacingOccurrences(of: "x", with: "0")
            .split(separator: ".")
            .compactMap { Int($0.filter { $0.isNumber }) }
        
        let latestParts = latest
            .replacingOccurrences(of: "^", with: "")
            .replacingOccurrences(of: "~", with: "")
            .split(separator: ".")
            .compactMap { Int($0.filter { $0.isNumber }) }
        
        // Compare version parts
        for (c, l) in zip(currentParts, latestParts) {
            if l > c { return true }
            if c > l { return false }
        }
        
        // If current has fewer parts, consider it older
        return latestParts.count > currentParts.count
    }
}
