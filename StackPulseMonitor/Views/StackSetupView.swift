import SwiftUI

// Import shared types (already defined in StackView.swift)
private enum SetupImportSheetType: Identifiable {
    case repoList
    case importPreview([GitHubRepository])
    
    var id: String {
        switch self {
        case .repoList: return "repoList"
        case .importPreview: return "importPreview"
        }
    }
}

struct StackSetupView: View {
    let viewModel: AppViewModel
    let onComplete: () -> Void
    
    // GitHub OAuth
    @StateObject private var authService = GitHubAuthService.shared
    @State private var showRepoList = false  // Deprecated, use activeSheet

    @State private var selectedPresets: Set<String> = []
    @State private var customName = ""
    @State private var customVersion = ""
    @State private var customType: TechType = .npm
    @State private var expandedCategories: Set<TechCategory> = Set(TechCategory.allCases)

    private let categories: [TechCategory] = [.frontend, .backend, .database, .devops, .language]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Build Your Stack")
                        .font(.title.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Add the technologies you actually use")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        // GitHub Import Section
                        VStack(spacing: 16) {
                            if authService.isAuthenticated {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Connected to GitHub")
                                                .font(.headline)
                                                .foregroundStyle(Theme.textPrimary)
                                            Text(authService.username ?? "")
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                        Spacer()
                                    }
                                    
                                    Button {
                                            activeSheet = .repoList
                                    } label: {
                                        HStack {
                                            Image(systemName: "minus.circle")
                                            Text("Add from GitHub")
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Theme.accent)
                                        .clipShape(.rect(cornerRadius: 8))
                                    }
                                }
                            } else {
                                GitHubAuthButton {
                                    activeSheet = .repoList
                                }
                            }
                        }
                        .padding(16)
                        .cardStyle()

                        ForEach(categories, id: \.self) { category in
                            categorySection(category)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Technology")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            HStack(alignment: .top, spacing: 8) {
                                VStack(spacing: 8) {
                                    TextField("Package name...", text: $customName)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.body)
                                        .foregroundStyle(Theme.textPrimary)
                                        .padding(10)
                                        .background(Theme.cardBackground)
                                        .clipShape(.rect(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Theme.border, lineWidth: 1)
                                        )
                                    
                                    TextField("Version (e.g., 1.2.3)", text: $customVersion)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.body)
                                        .foregroundStyle(Theme.textSecondary)
                                        .padding(10)
                                        .background(Theme.cardBackground)
                                        .clipShape(.rect(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Theme.border, lineWidth: 1)
                                        )
                                }

                                Button {
                                    addCustomTech()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 88)
                                        .background(Theme.accent)
                                        .clipShape(.rect(cornerRadius: 8))
                                }
                                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(16)
                        .cardStyle()

                        if !viewModel.projects.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Projects (\(viewModel.projects.count))")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)

                                ForEach(viewModel.projects) { project in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(project.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Theme.textPrimary)
                                            Text("\(project.dependencyCount) dependencies")
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                        Spacer()
                                        Button {
                                            viewModel.removeProject(project, deleteDependencies: true)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                    .padding(10)
                                    .background(Theme.accent.opacity(0.08))
                                    .clipShape(.rect(cornerRadius: 8))
                                }
                            }
                            .padding(16)
                            .cardStyle()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            VStack {
                Spacer()
                Button {
                    // Create "My Stack" project from selections ONLY during initial setup
                    // This won't recreate it if user deletes the project later
                    if viewModel.projects.isEmpty && !viewModel.stackItems.isEmpty {
                        let stackProject = Project(
                            name: "My Stack",
                            source: .manual,
                            dependencies: viewModel.stackItems.map { tech in
                                Dependency(
                                    name: tech.name,
                                    type: tech.type,
                                    category: tech.category,
                                    currentVersion: tech.currentVersion,
                                    latestVersion: nil
                                )
                            }
                        )
                        viewModel.addProject(stackProject)
                        // Clear stackItems so project won't auto-recreate on relaunch
                        viewModel.stackItems.removeAll()
                        StorageService.shared.saveStack([])
                    }
                    viewModel.completeSetup()
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Text("FINISH SETUP")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.projects.isEmpty && viewModel.stackItems.isEmpty ? Theme.muted : Theme.accent)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .disabled(viewModel.projects.isEmpty && viewModel.stackItems.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [Theme.background.opacity(0), Theme.background, Theme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .repoList:
                GitHubRepoListView(onReposSelected: { repos in
                    pendingImportRepos = repos
                    activeSheet = .importPreview(repos)
                })
            case .importPreview(let repos):
                // Reuse ImportPreviewView from StackView.swift
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

    @State private var activeSheet: SetupImportSheetType?
    @State private var pendingImportRepos: [GitHubRepository] = []

    private func performImport(repos: [GitHubRepository]) async {
        let token = GitHubAuthService.shared.getAccessTokenFromKeychain() ?? ""
        
        for repo in repos {
            // Create Project
            var project = Project(
                name: repo.name,
                source: .github,
                githubFullName: repo.fullName
            )
            
            // Detect dependencies
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
            
            print("✅ Imported project: \(project.name) with \(project.dependencyCount) deps")
        }
    }

    private func categorySection(_ category: TechCategory) -> some View {
        let presets = PresetTech.forCategory(category)
        return VStack(alignment: .leading, spacing: 10) {
            Text(category.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(presets, id: \.name) { preset in
                    let isSelected = selectedPresets.contains(preset.name)
                    Button {
                        togglePreset(preset)
                    } label: {
                        Text(preset.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Theme.accent : Theme.cardBackground)
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func togglePreset(_ preset: PresetTech) {
        if selectedPresets.contains(preset.name) {
            selectedPresets.remove(preset.name)
            viewModel.stackItems.removeAll { $0.name == preset.name }
            // BUG FIX: Persist the removal
            StorageService.shared.saveStack(viewModel.stackItems)
        } else {
            selectedPresets.insert(preset.name)
            let tech = Technology(
                name: preset.name,
                type: preset.type,
                identifier: preset.identifier,
                category: preset.category
            )
            viewModel.addTechnology(tech)
        }
    }

    private func addCustomTech() {
        let name = customName.trimmingCharacters(in: .whitespaces)
        let version = customVersion.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tech = Technology(
            name: name,
            type: customType,
            identifier: name.lowercased(),
            category: .other,
            currentVersion: version
        )
        viewModel.addTechnology(tech)
        customName = ""
        customVersion = ""
    }
}
