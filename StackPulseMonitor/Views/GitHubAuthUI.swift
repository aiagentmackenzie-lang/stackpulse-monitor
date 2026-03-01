import SwiftUI
import AuthenticationServices

/// Button for GitHub authentication
struct GitHubAuthButton: View {
    @StateObject private var authService = GitHubAuthService.shared
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var onSuccess: (() -> Void)?
    
    var body: some View {
        Button {
            authenticate()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "logo.github")
                    .font(.title3)
                
                if isAuthenticating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Text(authService.isAuthenticated ? "Connected to GitHub" : "Continue with GitHub")
                        .font(.headline.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(authService.isAuthenticated ? Color.green : Color(hex: "24292e"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(isAuthenticating)
        .alert("GitHub Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func authenticate() {
        guard !authService.isAuthenticated else {
            onSuccess?()
            return
        }
        
        isAuthenticating = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await authService.authenticate()
                await MainActor.run {
                    isAuthenticating = false
                    onSuccess?()
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

/// View showing list of GitHub repositories
struct GitHubRepoListView: View {
    @StateObject private var authService = GitHubAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var repositories: [GitHubRepository] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedRepos: Set<Int> = []
    
    var onRepoSelected: ((GitHubRepository) -> Void)?
    var onReposSelected: (([GitHubRepository]) -> Void)?
    
    var filteredRepos: [GitHubRepository] {
        if searchText.isEmpty {
            return repositories
        }
        return repositories.filter { repo in
            repo.name.localizedCaseInsensitiveContains(searchText) ||
            (repo.description ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0A").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.5))
                        
                        TextField("Search repositories...", text: $searchText)
                            .foregroundStyle(.white)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "1A1A1A"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Repo list
                    if isLoading {
                        Spacer()
                        ProgressView("Loading repositories...")
                            .tint(.white)
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)
                            Text(error)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                loadRepositories()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    } else if filteredRepos.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                            Text(searchText.isEmpty ? "No repositories found" : "No matching repositories")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        List {
                            Section {
                                ForEach(filteredRepos) { repo in
                                    MultiSelectRepoRow(
                                        repo: repo,
                                        isSelected: selectedRepos.contains(repo.id)
                                    )
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            toggleSelection(repo)
                                        }
                                }
                            } header: {
                                HStack {
                                    Text("\(filteredRepos.count) repositories")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                    Spacer()
                                    if !selectedRepos.isEmpty {
                                        Button("Clear (\(selectedRepos.count))") {
                                            selectedRepos.removeAll()
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .frame(maxHeight: .infinity)
                        
                        // Import button
                        if !selectedRepos.isEmpty {
                            Button {
                                let selected = repositories.filter { selectedRepos.contains($0.id) }
                                onReposSelected?(selected)
                                dismiss()
                            } label: {
                                Text("Import \(selectedRepos.count) Repos")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue)
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle("GitHub Repositories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if let username = authService.username {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                            Text(username)
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .onAppear {
                loadRepositories()
            }
        }
    }
    
    private func loadRepositories() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let token = authService.getAccessTokenFromKeychain() ?? ""
                let repos = try await GitHubAuthService.shared.fetchUserRepositories(token: token)
                await MainActor.run {
                    self.repositories = repos.sorted { $0.updatedAt ?? "" > $1.updatedAt ?? "" }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func toggleSelection(_ repo: GitHubRepository) {
        if selectedRepos.contains(repo.id) {
            selectedRepos.remove(repo.id)
        } else {
            selectedRepos.insert(repo.id)
        }
    }
}

/// Row with multi-select support
struct MultiSelectRepoRow: View {
    let repo: GitHubRepository
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? .blue : .white.opacity(0.3))
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1A1A"))
                    .frame(width: 44, height: 44)
                
                Image(systemName: repo.isPrivate ? "lock.fill" : "folder")
                    .font(.system(size: 18))
                    .foregroundStyle(repo.isPrivate ? .orange : .blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(repo.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if let description = repo.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("\(repo.stargazersCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(.yellow)
                    
                    if let language = repo.language {
                        Text(language)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    if let updatedAt = repo.updatedAt {
                        let formatted = formatDate(updatedAt)
                        Text(formatted)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color(hex: "1A1A1A"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.white.opacity(0.05), lineWidth: isSelected ? 2 : 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = RelativeDateTimeFormatter()
            displayFormatter.unitsStyle = .short
            return displayFormatter.localizedString(for: date, relativeTo: Date())
        }
        return dateString
    }
}

/// Row representing a repository
struct RepoRow: View {
    let repo: GitHubRepository
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1A1A"))
                    .frame(width: 44, height: 44)
                
                Image(systemName: repo.isPrivate ? "lock.fill" : "folder")
                    .font(.system(size: 18))
                    .foregroundStyle(repo.isPrivate ? .orange : .blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(repo.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if let description = repo.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("\(repo.stargazersCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(.yellow)
                    
                    if let language = repo.language {
                        Text(language)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    if let updatedAt = repo.updatedAt {
                        Text(formatDate(updatedAt))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1A1A"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Simple formatting - in production use proper Date parsing
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = RelativeDateTimeFormatter()
            displayFormatter.unitsStyle = .short
            return displayFormatter.localizedString(for: date, relativeTo: Date())
        }
        return dateString
    }
}

/// View for browsing repository files and detecting dependencies
struct GitHubRepoBrowserView: View {
    let repository: GitHubRepository
    @StateObject private var authService = GitHubAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var dependencyFiles: [GitHubFile] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFile: GitHubFile?
    @State private var detectedDependencies: [DetectedDependency] = []
    @State private var isParsing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0A").ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Repo header
                    RepoHeader(repo: repository)
                    
                    if isLoading {
                        Spacer()
                        ProgressView("Scanning repository...")
                            .tint(.white)
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)
                            Text(error)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    } else if dependencyFiles.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "doc.questionmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("No dependency files found")
                                .foregroundStyle(.white.opacity(0.6))
                            Text("StackPulse looks for package.json, go.mod, Cargo.toml, requirements.txt, etc.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    } else {
                        // Files list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detected Dependencies")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text("\(dependencyFiles.count) manifest file(s) found")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                            
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(dependencyFiles) { file in
                                        FileRow(file: file)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedFile = file
                                                parseFile(file)
                                            }
                                            .overlay(
                                                selectedFile?.id == file.id ?
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue, lineWidth: 2) :
                                                nil
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Parsed dependencies
                        if isParsing {
                            ProgressView("Parsing dependencies...")
                                .tint(.white)
                                .padding()
                        } else if !detectedDependencies.isEmpty {
                            DependenciesList(dependencies: detectedDependencies)
                        }
                        
                        Spacer()
                        
                        // Import button
                        if !detectedDependencies.isEmpty {
                            Button {
                                importDependencies()
                            } label: {
                                Text("Import \(detectedDependencies.count) Dependencies")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue)
                                    )
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle("Import Dependencies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                scanRepository()
            }
        }
    }
    
    private func scanRepository() {
        isLoading = true
        
        Task {
            do {
                let token = authService.getAccessTokenFromKeychain() ?? ""
                let files = try await GitHubAuthService.shared.detectDependencyFiles(
                    in: repository,
                    token: token
                )
                await MainActor.run {
                    self.dependencyFiles = files
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func parseFile(_ file: GitHubFile) {
        isParsing = true
        detectedDependencies = []
        
        Task {
            do {
                let token = authService.getAccessTokenFromKeychain() ?? ""
                let deps = try await GitHubAuthService.shared.parseDependencies(
                    from: file,
                    token: token
                )
                await MainActor.run {
                    self.detectedDependencies = deps
                    self.isParsing = false
                }
            } catch {
                await MainActor.run {
                    self.isParsing = false
                }
            }
        }
    }
    
    private func importDependencies() {
        // This would integrate with your technology stack
        // For now, just dismiss
        dismiss()
    }
}

// MARK: - Supporting Views

struct RepoHeader: View {
    let repo: GitHubRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: repo.isPrivate ? "lock.fill" : "folder")
                    .foregroundStyle(repo.isPrivate ? .orange : .blue)
                Text(repo.fullName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            if let description = repo.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "star")
                    Text("\(repo.stargazersCount)")
                }
                
                if let language = repo.language {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(languageColor(language))
                            .frame(width: 8, height: 8)
                        Text(language)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1A1A"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private func languageColor(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript", "typescript": return .yellow
        case "python": return .blue
        case "go": return .cyan
        case "rust": return .brown
        case "java", "kotlin": return .orange
        default: return .gray
        }
    }
}

struct FileRow: View {
    let file: GitHubFile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForFile(file.name))
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(ecosystemForFile(file.name))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1A1A"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func iconForFile(_ name: String) -> String {
        switch name {
        case "package.json": return "shippingbox.fill"
        case "go.mod", "go.sum": return "g.square.fill"
        case "Cargo.toml", "Cargo.lock": return "cube.fill"
        case "requirements.txt", "pyproject.toml": return "leaf.fill"
        case "Gemfile", "Gemfile.lock": return "gem.fill"
        case "composer.json", "composer.lock": return "music.note"
        default: return "doc.text.fill"
        }
    }
    
    private func ecosystemForFile(_ name: String) -> String {
        switch name {
        case "package.json": return "NPM"
        case "go.mod", "go.sum": return "Go Modules"
        case "Cargo.toml", "Cargo.lock": return "Cargo"
        case "requirements.txt", "pyproject.toml": return "Python"
        case "Gemfile", "Gemfile.lock": return "Ruby"
        case "composer.json", "composer.lock": return "PHP"
        default: return "Unknown"
        }
    }
}

struct DependenciesList: View {
    let dependencies: [DetectedDependency]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Found Dependencies")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(dependencies.prefix(10)) { dep in
                        HStack {
                            Text(dep.name)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(dep.version)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    if dependencies.count > 10 {
                        Text("+ \(dependencies.count - 10) more")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 4)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1A1A1A"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
