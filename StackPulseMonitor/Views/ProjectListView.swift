import SwiftUI

struct ProjectListView: View {
    @State var viewModel: AppViewModel
    @State private var selectedProject: Project?
    @State private var showDeleteAlert = false
    @State private var projectToDelete: Project?
    @State private var deleteWithDeps = true
    @State private var activeSheet: AddSheetType?
    @State private var pendingImportRepos: [GitHubRepository] = []
    
    enum AddSheetType: Identifiable {
        case manual
        case githubRepos
        case importPreview([GitHubRepository])
        
        var id: String {
            switch self {
            case .manual: return "manual"
            case .githubRepos: return "githubRepos"
            case .importPreview: return "importPreview"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header stats
                ProjectStatsHeader(
                    projectCount: viewModel.projects.count,
                    depCount: viewModel.totalDependencies,
                    outdatedCount: viewModel.totalOutdated
                )
                
                // Projects
                ForEach(viewModel.projects) { project in
                    ProjectCard(
                        project: project,
                        viewModel: viewModel,
                        onDelete: { projectToDelete = $0; showDeleteAlert = true },
                        onToggle: { viewModel.toggleProjectExpansion($0) }
                    )
                }
                
                if viewModel.projects.isEmpty {
                    EmptyProjectsView()
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Projects")
        .alert("Delete Project?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button(deleteWithDeps ? "Delete Project + Dependencies" : "Delete Project Only", role: .destructive) {
                if let project = projectToDelete {
                    viewModel.removeProject(project, deleteDependencies: deleteWithDeps)
                }
            }
        } message: {
            if let project = projectToDelete {
                Text("\"\(project.name)\" has \(project.dependencyCount) dependencies.\n\nDelete dependencies too?")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        activeSheet = .manual
                    } label: {
                        Label("Add Manually", systemImage: "plus")
                    }
                    
                    Button {
                        activeSheet = .githubRepos
                    } label: {
                        Label("Import from GitHub", systemImage: "logo.github")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .manual:
                AddManualProjectView(viewModel: viewModel)
            case .githubRepos:
                GitHubRepoListView(onReposSelected: { repos in
                    pendingImportRepos = repos
                    activeSheet = .importPreview(repos)
                })
            case .importPreview(let repos):
                ImportPreviewView(
                    repositories: repos,
                    onConfirm: {
                        Task {
                            await performImport(repos: repos)
                            activeSheet = nil
                        }
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
            }
        }
    }
    
    /// Imports repositories from GitHub with full metadata enrichment.
    /// Fetches: description, README, topics, languages, stars, forks, license, activity.
    /// Data stored in Project and accessed by AIContextBuilder for AI chat context.
    private func performImport(repos: [GitHubRepository]) async {
        let token = GitHubAuthService.shared.getAccessTokenFromKeychain() ?? ""
        
        for repo in repos {
            var project = Project(
                name: repo.name,
                source: .github,
                githubFullName: repo.fullName
            )
            
            // ALWAYS set basic enrichment from repo list (this always works)
            project.description = repo.description
            project.starsCount = repo.stargazersCount
            
            // Try to fetch additional enrichment data (README, topics, languages)
            print("🔍 Fetching metadata for \(repo.fullName)...")
            do {
                let metadata = try await GitHubAuthService.shared.fetchRepoMetadata(
                    repo: repo,
                    token: token
                )
                
                print("✅ Got metadata for \(repo.name):")
                print("  - Description: \(metadata.description ?? "nil")")
                print("  - Stars: \(metadata.starsCount ?? 0)")
                print("  - Topics: \(metadata.topics ?? [])")
                print("  - Languages: \(metadata.languageStats?.keys.sorted() ?? [])")
                
                // Enrich project with GitHub data (override with richer data)
                if let desc = metadata.description, !desc.isEmpty {
                    project.description = desc
                }
                project.readmeContent = metadata.readmeContent
                project.topics = metadata.topics
                project.starsCount = metadata.starsCount
                project.forksCount = metadata.forksCount
                project.license = metadata.license
                project.lastCommitDate = metadata.lastCommitDate
                project.defaultBranch = metadata.defaultBranch
                project.languageStats = metadata.languageStats
                
                print("✅ Enriched \(repo.name): \(metadata.starsCount ?? 0) stars, \(metadata.topics?.count ?? 0) topics")
            } catch {
                print("❌ Failed to fetch metadata for \(repo.name):")
                print("  Error: \(error)")
                print("  Token empty: \(token.isEmpty)")
                // Continue - project still has repo.description and repo.stargazersCount
            }
            
            do {
                let files = try await GitHubAuthService.shared.detectDependencyFiles(
                    in: repo,
                    token: token
                )
                
                for file in files {
                    let detectedDeps = try await GitHubAuthService.shared.parseDependencies(
                        from: file,
                        token: token
                    )
                    
                    for dep in detectedDeps {
                        let techType = TechnologyKnowledge.techType(from: dep.ecosystem)
                        let category = dep.isDev ? .devops : TechnologyKnowledge.classify(
                            name: dep.name,
                            ecosystem: techType
                        )
                        
                        let dependency = Dependency(
                            name: dep.name,
                            type: techType,
                            category: category,
                            currentVersion: dep.version,
                            latestVersion: nil
                        )
                        project.dependencies.append(dependency)
                    }
                }
            } catch {
                print("⚠️ Failed to detect deps for \(repo.name): \(error)")
            }
            
            await MainActor.run {
                viewModel.addProject(project)
            }
        }
    }
}

// MARK: - Add Manual Project View

struct AddManualProjectView: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedType: TechType = .language
    @State private var selectedCategory: TechCategory = .backend
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(TechType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TechCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Add Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let project = Project(
                            name: name,
                            source: .manual,
                            dependencies: []
                        )
                        viewModel.addProject(project)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    let project: Project
    var viewModel: AppViewModel
    let onDelete: (Project) -> Void
    let onToggle: (Project) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button { onToggle(project) } label: {
                HStack(spacing: 12) {
                    // Expand/collapse icon
                    Image(systemName: project.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(Theme.textSecondary)
                        .font(.caption.weight(.semibold))
                    
                    // Project icon
                    Image(systemName: project.isFromGitHub ? "logo.github" : "folder")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        
                        // GitHub enrichment display - always visible
                        if project.source == .github {
                            HStack(spacing: 12) {
                                if let stars = project.starsCount, stars > 0 {
                                    Label("\(stars)", systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                                if let forks = project.forksCount, forks > 0 {
                                    Label("\(forks)", systemImage: "tuningfork")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                if let license = project.license {
                                    Text(license)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                        
                        // Project description - always visible, larger
                        if let description = project.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(3)
                                .padding(.top, 4)
                        }
                        
                        HStack(spacing: 8) {
                            Label("\(project.dependencyCount)", systemImage: "shippingbox")
                                .font(.caption)
                            if project.outdatedCount > 0 {
                                Label("\(project.outdatedCount)", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Source badge
                    SourceBadge(source: project.source)
                    
                    // Delete button
                    Button { onDelete(project) } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.6))
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Dependencies (if expanded)
            if project.isExpanded {
                
                if !project.dependencies.isEmpty {
                    Divider()
                        .background(Theme.border)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(project.dependencies) { dep in
                            DependencyRow(dependency: dep)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(hex: 0x1A1A1A))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Dependency Row

struct DependencyRow: View {
    let dependency: Dependency
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: iconForType(dependency.type))
                .foregroundStyle(colorForCategory(dependency.category))
                .font(.caption)
                .frame(width: 24)
            
            // Name
            Text(dependency.name)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            // Version info
            HStack(spacing: 4) {
                Text(dependency.currentVersion)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                
                if dependency.isOutdated, let latest = dependency.latestVersion {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(latest)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            // Category badge
            CategoryBadge(category: dependency.category)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: TechType) -> String {
        switch type {
        case .npm: return "shippingbox"
        case .pypi: return "leaf"
        case .cargo: return "cube"
        case .gomod: return "g.circle"
        case .maven, .gradle: return "j.circle"
        case .gem: return "diamond"
        case .composer: return "c.circle"
        case .github: return "logo.github"
        case .language: return "chevron.left.forwardslash.chevron.right"
        case .platform: return "cloud"
        }
    }
    
    private func colorForCategory(_ category: TechCategory) -> Color {
        switch category {
        case .frontend: return .blue
        case .backend: return .green
        case .database: return .orange
        case .devops: return .purple
        case .language: return .cyan
        case .other: return .gray
        }
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: TechCategory
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    
    private var color: Color {
        switch category {
        case .frontend: return .blue
        case .backend: return .green
        case .database: return .orange
        case .devops: return .purple
        case .language: return .cyan
        case .other: return .gray
        }
    }
}

// MARK: - Source Badge

struct SourceBadge: View {
    let source: ProjectSource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: source == .github ? "logo.github" : "person")
                .font(.caption2)
            Text(source.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.accent.opacity(0.2))
        .foregroundStyle(Theme.accent)
        .clipShape(Capsule())
    }
}

// MARK: - Header Stats

struct ProjectStatsHeader: View {
    let projectCount: Int
    let depCount: Int
    let outdatedCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(value: projectCount, label: "Projects", icon: "folder")
            StatCard(value: depCount, label: "Dependencies", icon: "shippingbox")
            if outdatedCount > 0 {
                StatCard(value: outdatedCount, label: "Outdated", icon: "exclamationmark.triangle", color: .orange)
            }
        }
    }
}

struct StatCard: View {
    let value: Int
    let label: String
    let icon: String
    var color: Color = Theme.accent
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: 0x1A1A1A))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty State

struct EmptyProjectsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Theme.textSecondary)
            
            Text("No Projects Yet")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            
            Text("Import from GitHub or add dependencies manually")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
