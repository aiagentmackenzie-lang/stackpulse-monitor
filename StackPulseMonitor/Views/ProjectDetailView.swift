import SwiftUI

/// Detail view for a single project showing its dependencies
struct ProjectDetailView: View {
    let projectId: UUID
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isChecking = false
    @State private var checkProgress: Double = 0
    
    // Look up project from viewModel so updates are live
    private var project: Project {
        viewModel.projects.first { $0.id == projectId } ?? Project(
            name: "Unknown",
            source: .manual,
            dependencies: []
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with health score
                headerSection
                
                // Check for Updates button
                checkButtonSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                
                // Dependencies by category
                dependenciesSection
            }
        }
        .background(Theme.background)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Health score display
            let score = healthScore
            let color = healthColor(for: score)
            
            VStack(spacing: 8) {
                Text("Health Score")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                
                Text("\(score)%")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                
                // Score bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: 0x2A2A2A))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(score) / 100, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 40)
            }
            .padding(.top, 8)
            
            // Stats row
            HStack(spacing: 24) {
                StatBadge(value: project.dependencyCount, label: "Total", icon: "shippingbox")
                StatBadge(value: project.outdatedCount, label: "Outdated", icon: "exclamationmark.triangle", color: .orange)
                StatBadge(value: unknownCount, label: "Unknown", icon: "questionmark.circle", color: .gray)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(hex: 0x1A1A1A))
        )
    }
    
    // MARK: - Check Button Section
    
    private var checkButtonSection: some View {
        Button {
            Task {
                await checkVersions()
            }
        } label: {
            HStack(spacing: 12) {
                if isChecking {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                    
                    Text("Checking... \(Int(checkProgress * 100))%")
                        .font(.headline)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                    
                    Text("Check for Updates")
                        .font(.headline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isChecking ? Theme.muted : Theme.accent)
            .clipShape(.rect(cornerRadius: 12))
        }
        .disabled(isChecking)
    }
    
    // MARK: - Dependencies Section
    
    private var dependenciesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Group by category
            ForEach(TechCategory.allCases, id: \.self) { category in
                let deps = dependencies(in: category)
                if !deps.isEmpty {
                    categorySection(category: category, dependencies: deps)
                }
            }
        }
        .padding(16)
    }
    
    private func categorySection(category: TechCategory, dependencies: [Dependency]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack {
                Text(category.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                
                Text("\(dependencies.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.muted.opacity(0.2))
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            // Dependency rows
            VStack(spacing: 0) {
                ForEach(dependencies) { dep in
                    ProjectDetailDependencyRow(
                        projectId: projectId,
                        dependencyId: dep.id,
                        viewModel: viewModel
                    )
                    
                    if dep.id != dependencies.last?.id {
                        Divider()
                            .background(Theme.border)
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helpers
    
    private func dependencies(in category: TechCategory) -> [Dependency] {
        project.dependencies.filter { $0.category == category }
    }
    
    private var unknownCount: Int {
        project.dependencies.filter { $0.latestVersion == nil }.count
    }
    
    private var healthScore: Int {
        let withKnownLatest = project.dependencies.filter { $0.latestVersion != nil }
        guard !withKnownLatest.isEmpty else { return 0 }
        let upToDate = withKnownLatest.filter { !$0.isOutdated }
        return Int((Double(upToDate.count) / Double(withKnownLatest.count)) * 100)
    }
    
    private func healthColor(for score: Int) -> Color {
        switch score {
        case 0..<50: return .red
        case 50..<80: return .orange
        default: return .green
        }
    }
    
    // MARK: - Actions
    
    private func checkVersions() async {
        isChecking = true
        checkProgress = 0
        
        await viewModel.checkVersions(forProjectId: projectId)
        
        isChecking = false
    }
}

// MARK: - Dependency Row

struct ProjectDetailDependencyRow: View {
    let projectId: UUID
    let dependencyId: UUID
    @Bindable var viewModel: AppViewModel
    
    // Look up live dependency from viewModel
    private var dependency: Dependency? {
        guard let project = viewModel.projects.first(where: { $0.id == projectId }),
              let dep = project.dependencies.first(where: { $0.id == dependencyId }) else {
            return nil
        }
        return dep
    }
    
    var body: some View {
        if let dep = dependency {
            dependencyRowContent(dep)
        }
    }
    
    private func dependencyRowContent(_ dependency: Dependency) -> some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon(for: dependency)
                .frame(width: 24)
            
            // Name and version info
            VStack(alignment: .leading, spacing: 4) {
                Text(dependency.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                
                // Version info
                if let latest = dependency.latestVersion {
                    HStack(spacing: 4) {
                        Text("v\(dependency.currentVersion)")
                            .foregroundStyle(Theme.textSecondary)
                        
                        if dependency.isOutdated {
                            Image(systemName: "arrow.forward")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            
                            Text("v\(latest)")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                } else {
                    Text("v\(dependency.currentVersion)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            // Type badge
            Text(dependency.type.rawValue.uppercased())
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.muted.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func statusIcon(for dependency: Dependency) -> some View {
        if dependency.latestVersion == nil {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.gray)
                .font(.callout)
        } else if dependency.isOutdated {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.callout)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.callout)
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: Int
    let label: String
    let icon: String
    var color: Color = Theme.textSecondary
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview("Project Detail") {
    let vm = AppViewModel()
    let project = Project(
        name: "MyRepo",
        source: .github,
        githubFullName: "raphael/myrepo",
        dependencies: [
            Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0", latestVersion: "19.0.0", isOutdated: true),
            Dependency(name: "vue", type: .npm, category: .frontend, currentVersion: "3.4.0", latestVersion: "3.4.0", isOutdated: false),
            Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0", latestVersion: "4.19.0", isOutdated: true),
            Dependency(name: "lodash", type: .npm, category: .backend, currentVersion: "4.17.21", latestVersion: nil, isOutdated: false),
            Dependency(name: "jest", type: .npm, category: .devops, currentVersion: "29.0.0", latestVersion: "30.0.0", isOutdated: true)
        ]
    )
    vm.projects = [project]
    
    return NavigationStack {
        ProjectDetailView(projectId: project.id, viewModel: vm)
    }
    .preferredColorScheme(.dark)
}
