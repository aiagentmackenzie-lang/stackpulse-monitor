import SwiftUI

enum ImportSheetType: Identifiable {
    case repoList
    case importPreview([GitHubRepository])
    
    var id: String {
        switch self {
        case .repoList: return "repoList"
        case .importPreview: return "importPreview"
        }
    }
}

struct StackView: View {
    let viewModel: AppViewModel
    @State private var showAddSheet = false
    @State private var selectedTech: Technology?
    @State private var expandedCategories: Set<TechCategory> = Set(TechCategory.allCases)
    @State private var activeSheet: ImportSheetType?

    private var groupedItems: [(TechCategory, [Technology])] {
        let grouped = Dictionary(grouping: viewModel.stackItems) { $0.category }
        return TechCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.stackItems.isEmpty {
                    ContentUnavailableView("No Technologies", systemImage: "shippingbox", description: Text("Add technologies to monitor your stack"))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(groupedItems, id: \.0) { category, items in
                            categorySection(category: category, items: items)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
                }
            }
            .background(Theme.background)
            .navigationTitle("My Stack")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.accent)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(viewModel.stackItems.count) items")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .sheet(isPresented: $showAddSheet) {
                AddTechnologySheet(viewModel: viewModel)
            }
            .sheet(item: $selectedTech) { tech in
                TechnologyDetailView(viewModel: viewModel, technology: tech)
            }
        }
    }

    private func categorySection(category: TechCategory, items: [Technology]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    Text("\(category.rawValue) (\(items.count))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 4)

            if expandedCategories.contains(category) {
                ForEach(items) { tech in
                    Button {
                        selectedTech = tech
                    } label: {
                        stackItemRow(tech)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func stackItemRow(_ tech: Technology) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tech.status.color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: tech.status.icon)
                        .font(.caption)
                        .foregroundStyle(tech.status.color)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(tech.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(tech.currentVersion.isEmpty ? "No version set" : "v\(tech.currentVersion)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(tech.status.label)
                .font(.caption2.bold())
                .foregroundStyle(tech.status.color)
        }
        .padding(.vertical, 4)
    }
}

struct AddTechnologySheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AppViewModel
    
    // GitHub OAuth
    @StateObject private var authService = GitHubAuthService.shared
    @State private var showRepoList = false

    @State private var searchText = ""
    @State private var searchResults: [NPMSearchPackage] = []
    @State private var isSearching = false
    @State private var manualName = ""
    @State private var manualType: TechType = .npm
    @State private var manualCategory: TechCategory = .other
    @State private var manualVersion = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedRepos: [GitHubRepository] = []
    @State private var activeSheet: ImportSheetType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search NPM")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.textSecondary)
                            TextField("Search packages...", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .padding(12)
                        .background(Color(hex: 0x1A1A1A))
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.border, lineWidth: 1)
                        )

                        if isSearching {
                            HStack {
                                ProgressView().tint(Theme.accent)
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(.top, 4)
                        }

                        ForEach(searchResults, id: \.name) { pkg in
                            Button {
                                addFromSearch(pkg)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pkg.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Theme.textPrimary)
                                        if let desc = pkg.description {
                                            Text(desc)
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Text("v\(pkg.version)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.muted)
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Theme.accent)
                                }
                                .padding(10)
                                .background(Theme.cardBackground)
                                .clipShape(.rect(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // GitHub Import Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Import from GitHub")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        
                        if authService.isAuthenticated {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Connected")
                                            .font(.subheadline.weight(.semibold))
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
                    .sheet(item: $activeSheet) { sheet in
                        switch sheet {
                        case .repoList:
                            GitHubRepoListView(onReposSelected: { repos in
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manual Entry")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        TextField("Technology name", text: $manualName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(Color(hex: 0x1A1A1A))
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.border, lineWidth: 1)
                            )

                        TextField("Version (optional)", text: $manualVersion)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(Color(hex: 0x1A1A1A))
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.border, lineWidth: 1)
                            )

                        HStack(spacing: 8) {
                            Picker("Type", selection: $manualType) {
                                ForEach(TechType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.accent)

                            Picker("Category", selection: $manualCategory) {
                                ForEach(TechCategory.allCases, id: \.self) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.accent)
                        }

                        Button {
                            addManual()
                        } label: {
                            Text("ADD TO STACK")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(manualName.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.muted : Theme.accent)
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        .disabled(manualName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(16)
                    .cardStyle()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .navigationTitle("Add Technology")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                guard newValue.count >= 2 else {
                    searchResults = []
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    isSearching = true
                    do {
                        let results = try await NetworkService.shared.searchNPM(newValue)
                        if !Task.isCancelled {
                            searchResults = results
                        }
                    } catch {
                        if !Task.isCancelled {
                            searchResults = []
                        }
                    }
                    isSearching = false
                }
            }
        }
    }

    private func addFromSearch(_ pkg: NPMSearchPackage) {
        let tech = Technology(
            name: pkg.name,
            type: .npm,
            identifier: pkg.name,
            category: .other,
            latestVersion: pkg.version
        )
        viewModel.addTechnology(tech)
        dismiss()
    }

    private func addManual() {
        let name = manualName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tech = Technology(
            name: name,
            type: manualType,
            identifier: name.lowercased(),
            category: manualCategory,
            currentVersion: manualVersion
        )
        viewModel.addTechnology(tech)
        dismiss()
    }
    
    private func handleImportedRepos(_ repos: [GitHubRepository]) {
        // This is called by GitHubRepoListView
        // The actual handling is done in the sheet(item:) modifier
    }
    
    private func performImport(repos: [GitHubRepository]) async {
        let token = GitHubAuthService.shared.getAccessTokenFromKeychain() ?? ""
        
        for repo in repos {
            // Create new Project
            var project = Project(
                name: repo.name,
                source: .github,
                githubFullName: repo.fullName
            )
            
            // ALWAYS set basic enrichment from repo list (this always works)
            project.description = repo.description
            project.starsCount = repo.stargazersCount
            
            // Try to fetch additional enrichment data (README, topics, languages)
            print("🔍 [StackView] Fetching metadata for \(repo.fullName)...")
            do {
                let metadata = try await GitHubAuthService.shared.fetchRepoMetadata(
                    repo: repo,
                    token: token
                )
                
                print("✅ [StackView] Got metadata for \(repo.name)")
                
                // Override with richer data from API
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
            } catch {
                print("❌ [StackView] Failed to fetch metadata: \(error)")
                // Fallback: project still has repo.description and repo.stargazersCount
            }
            
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
            
            print("✅ Imported project: \(project.name) with \(project.dependencyCount) dependencies")
        }
        
        await MainActor.run {
            dismiss()
        }
    }
}

// MARK: - Import Preview View

struct ImportPreviewView: View {
    let repositories: [GitHubRepository]
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var isScanning = true
    @State private var scanResults: [(repo: GitHubRepository, files: [GitHubFile], deps: [DetectedDependency])] = []
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isScanning {
                        Spacer()
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Theme.accent)
                            
                            Text("Scanning \(repositories.count) repo\(repositories.count == 1 ? "" : "s")...")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            
                            Text("Detecting package.json, requirements.txt, and other dependency files")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)
                            Text(error)
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                startScan()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(scanResults, id: \.repo.id) { result in
                                    RepoScanResultCard(
                                        repo: result.repo,
                                        files: result.files,
                                        deps: result.deps
                                    )
                                }
                            }
                            .padding(16)
                        }
                        
                        // Bottom action bar
                        VStack(spacing: 12) {
                            let totalDeps = scanResults.reduce(0) { $0 + $1.deps.count }
                            let totalFiles = scanResults.reduce(0) { $0 + $1.files.count }
                            
                            Text("Found \(totalDeps) dependencies across \(totalFiles) files")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                            
                            HStack(spacing: 12) {
                                Button("Cancel") {
                                    onCancel()
                                }
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: 0x1A1A1A))
                                )
                                
                                Button {
                                    onConfirm()
                                } label: {
                                    Text("Import \(totalDeps) Dependencies")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Theme.accent)
                                        )
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            Rectangle()
                                .fill(Theme.background)
                                .shadow(color: .black.opacity(0.3), radius: 8, y: -4)
                        )
                    }
                }
            }
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            .onAppear {
                startScan()
            }
        }
    }
    
    private func startScan() {
        isScanning = true
        errorMessage = nil
        scanResults = []
        
        print("🔍🔍🔍 ImportPreview: Starting scan for \(repositories.count) repos")
        
        Task {
            do {
                let token = GitHubAuthService.shared.getAccessTokenFromKeychain() ?? ""
                print("🔍 Token length: \(token.count)")
                
                var results: [(GitHubRepository, [GitHubFile], [DetectedDependency])] = []
                
                for repo in repositories {
                    print("🔍 Scanning repo: \(repo.fullName)")
                    
                    let files = try await GitHubAuthService.shared.detectDependencyFiles(
                        in: repo,
                        token: token
                    )
                    print("🔍 Found \(files.count) dependency files in \(repo.name)")
                    
                    var allDeps: [DetectedDependency] = []
                    for file in files {
                        print("🔍 Parsing file: \(file.name)")
                        do {
                            let deps = try await GitHubAuthService.shared.parseDependencies(
                                from: file,
                                token: token
                            )
                            print("🔍 Parsed \(deps.count) deps from \(file.name)")
                            allDeps.append(contentsOf: deps)
                        } catch {
                            print("❌ Failed to parse \(file.name): \(error)")
                        }
                    }
                    
                    results.append((repo, files, allDeps))
                }
                
                print("✅ Scan complete. Total repos: \(results.count)")
                
                await MainActor.run {
                    self.scanResults = results
                    self.isScanning = false
                }
            } catch {
                print("❌ Scan failed: \(error)")
                await MainActor.run {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isScanning = false
                }
            }
        }
    }
}

struct RepoScanResultCard: View {
    let repo: GitHubRepository
    let files: [GitHubFile]
    let deps: [DetectedDependency]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Label("\(files.count) file\(files.count == 1 ? "" : "s")", systemImage: "doc.text")
                            .font(.caption)
                        Label("\(deps.count) dep\(deps.count == 1 ? "" : "s")", systemImage: "shippingbox")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            if isExpanded {
                Divider()
                    .background(Theme.border)
                
                if files.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                        Text("No dependency files detected")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    // Files found
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Files")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .textCase(.uppercase)
                        
                        ForEach(files, id: \.sha) { file in
                            HStack {
                                Image(systemName: iconForFile(file.name))
                                    .foregroundStyle(Theme.accent)
                                Text(file.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(ecosystemForFile(file.name))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    
                    if !deps.isEmpty {
                        Divider()
                            .background(Theme.border)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sample Dependencies")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .textCase(.uppercase)
                            
                            ForEach(deps.prefix(5), id: \.id) { dep in
                                let techType = TechnologyKnowledge.techType(from: dep.ecosystem)
                                let category = dep.isDev ? .devops : TechnologyKnowledge.classify(
                                    name: dep.name,
                                    ecosystem: techType
                                )
                                
                                HStack {
                                    Text(dep.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(category.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(categoryColor(category).opacity(0.2))
                                        .foregroundStyle(categoryColor(category))
                                        .clipShape(Capsule())
                                }
                            }
                            
                            if deps.count > 5 {
                                Text("+ \(deps.count - 5) more")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: 0x1A1A1A))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private func iconForFile(_ name: String) -> String {
        switch name {
        case "package.json": return "shippingbox.fill"
        case "go.mod", "go.sum": return "g.square.fill"
        case "Cargo.toml", "Cargo.lock": return "cube.fill"
        case "requirements.txt", "pyproject.toml": return "leaf.fill"
        case "Gemfile", "Gemfile.lock": return "diamond"
        case "composer.json", "composer.lock": return "c.square"
        default: return "doc.text.fill"
        }
    }
    
    private func ecosystemForFile(_ name: String) -> String {
        switch name {
        case "package.json": return "NPM"
        case "go.mod", "go.sum": return "Go"
        case "Cargo.toml", "Cargo.lock": return "Cargo"
        case "requirements.txt", "pyproject.toml": return "Python"
        case "Gemfile", "Gemfile.lock": return "Ruby"
        case "composer.json", "composer.lock": return "PHP"
        default: return "Unknown"
        }
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
}
