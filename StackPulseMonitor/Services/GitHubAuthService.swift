import Foundation
import Combine
import AuthenticationServices
import Security

/// Service for GitHub OAuth authentication and repository operations
@MainActor
final class GitHubAuthService: NSObject, ObservableObject {
    static let shared = GitHubAuthService()
    
    // GitHub OAuth Configuration
    // App ID: 2968147
    // ⚠️ SECURITY: In production, use environment variables or a secrets manager
    private let clientId = "Iv23li39MYGkp1UKBuka"
    private let clientSecret = "ee3c396a1855788a22a0f0245e3257ef45a48e88"
    private let callbackScheme = "stackpulse"
    private let callbackURL = "stackpulse://oauth/callback"
    
    // Keychain keys
    private let tokenKey = "github_access_token"
    private let usernameKey = "github_username"
    private let tokenExpiryKey = "github_token_expiry"
    
    @Published var isAuthenticated = false
    @Published var username: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var continuation: CheckedContinuation<String, Error>?

    override init() {
        super.init()
        checkExistingToken()
    }
    
    // MARK: - Authentication State
    
    private func checkExistingToken() {
        if let token = getAccessTokenFromKeychain() {
            Task {
                await validateToken(token)
            }
        }
    }
    
    private func validateToken(_ token: String) async {
        do {
            let user = try await fetchAuthenticatedUser(token: token)
            await MainActor.run {
                self.isAuthenticated = true
                self.username = user.login
                self.saveUsername(user.login)
            }
        } catch {
            // Token invalid, clear it
            await MainActor.run {
                self.clearAuthentication()
            }
        }
    }
    
    // MARK: - OAuth Flow
    
    /// Initiates GitHub OAuth authentication flow
    func authenticate() async throws -> String {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            // Build OAuth URL
            let state = generateState()
            
            var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
            components.queryItems = [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "scope", value: "repo read:user"),
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "redirect_uri", value: callbackURL)
            ]
            
            guard let authURL = components.url else {
                continuation.resume(throwing: GitHubAuthError.invalidURL)
                self.continuation = nil
                return
            }
            
            // Create authentication session
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, authError in
                guard let self = self else { return }
                
                if let authError = authError {
                    self.continuation?.resume(throwing: GitHubAuthError.userCancelled)
                    self.continuation = nil
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    self.continuation?.resume(throwing: GitHubAuthError.noCallback)
                    self.continuation = nil
                    return
                }
                
                Task {
                    do {
                        print("🔍 OAuth Step 1: Extracting code from callback...")
                        let code = try self.extractCode(from: callbackURL)
                        print("🔍 OAuth Step 2: Got code, exchanging for token...")
                        
                        let token = try await self.exchangeCodeForToken(code: code)
                        print("🔍 OAuth Step 3: Got token, fetching user...")
                        
                        // Fetch user info
                        let user = try await self.fetchAuthenticatedUser(token: token)
                        print("🔍 OAuth Step 4: Got user: \(user.login)")
                        
                        await MainActor.run {
                            self.isAuthenticated = true
                            self.username = user.login
                            self.saveAccessToken(token)
                            self.saveUsername(user.login)
                        }
                        
                        self.continuation?.resume(returning: token)
                    } catch {
                        print("❌ OAuth failed: \(error)")
                        if let authError = error as? GitHubAuthError {
                            print("❌ Error type: \(authError.localizedDescription)")
                        }
                        self.continuation?.resume(throwing: error)
                    }
                    self.continuation = nil
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            DispatchQueue.main.async {
                session.start()
            }
        }
    }
    
    // MARK: - Token Exchange
    
    private func exchangeCodeForToken(code: String) async throws -> String {
        let url = URL(string: "https://github.com/login/oauth/access_token")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "client_id=\(clientId)&client_secret=\(clientSecret)&code=\(code)&redirect_uri=\(callbackURL)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 Token exchange HTTP status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("❌ Token exchange failed with status: \(httpResponse.statusCode)")
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubAuthError.tokenExchangeFailed
        }
        
        // Parse access_token from response (form encoded)
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw GitHubAuthError.tokenParseFailed
        }
        
        // DEBUG: Write response to file for inspection
        let debugPath = FileManager.default.temporaryDirectory.appendingPathComponent("github_oauth_response.txt")
        try? responseString.write(to: debugPath, atomically: true, encoding: .utf8)
        print("🔍 DEBUG: Response saved to: \(debugPath.path)")
        
        // Debug: Print actual response
        print("🔍 GitHub OAuth Response (raw): \(responseString)")
        print("🔍 Response length: \(responseString.count) chars")
        
        // Check for error response first
        if responseString.contains("error=") {
            print("❌ GitHub returned error: \(responseString)")
            throw GitHubAuthError.apiError("GitHub OAuth error: \(responseString)")
        }
        
        // Extract access_token - try multiple formats
        var token: String?
        
        // Format 1: URL-encoded (access_token=xxx&scope=...)
        let components = responseString.components(separatedBy: "&")
        for component in components {
            let parts = component.components(separatedBy: "=")
            if parts.count >= 2 && parts[0] == "access_token" {
                token = parts[1]
                print("🔍 Found token using URL-encoded format")
                break
            }
        }
        
        // Format 2: Check if it's JSON
        if token == nil, let jsonData = responseString.data(using: .utf8) {
            print("🔍 Trying JSON parsing...")
            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                print("🔍 Parsed JSON: \(json)")
                if let accessToken = json["access_token"] as? String {
                    token = accessToken
                    print("🔍 Found token in JSON")
                }
            }
        }
        
        guard let accessToken = token else {
            print("❌ No access_token found in response. First 200 chars: \(String(responseString.prefix(200)))")
            throw GitHubAuthError.tokenParseFailed
        }
        
        print("✅ Got access token (length: \(accessToken.count))")
        return accessToken
    }
    
    // MARK: - Repository Operations
    
    /// Fetches user's repositories
    func fetchUserRepositories(token: String? = nil) async throws -> [GitHubRepository] {
        let accessToken = token ?? getAccessTokenFromKeychain() ?? ""
        
        guard !accessToken.isEmpty else {
            throw GitHubAuthError.notAuthenticated
        }
        
        let url = URL(string: "https://api.github.com/user/repos")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401 {
                clearAuthentication()
                throw GitHubAuthError.tokenExpired
            }
            throw GitHubAuthError.apiError("Failed to fetch repositories")
        }
        
        let repos = try JSONDecoder().decode([GitHubRepository].self, from: data)
        return repos
    }
    
    /// Fetches repository files at a path
    func fetchRepoFiles(
        repo: GitHubRepository,
        path: String = "",
        token: String? = nil
    ) async throws -> [GitHubFile] {
        let accessToken = token ?? getAccessTokenFromKeychain() ?? ""
        
        guard !accessToken.isEmpty else {
            throw GitHubAuthError.notAuthenticated
        }
        
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let url = URL(string: "https://api.github.com/repos/\(repo.fullName)/contents/\(encodedPath)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubAuthError.apiError("Failed to fetch repository files")
        }
        
        let files = try JSONDecoder().decode([GitHubFile].self, from: data)
        return files
    }
    
    /// Fetches raw file content from raw.githubusercontent.com
    func fetchRawContent(urlString: String, token: String? = nil) async throws -> String {
        let accessToken = token ?? getAccessTokenFromKeychain() ?? ""
        
        guard let url = URL(string: urlString) else {
            throw GitHubAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubAuthError.apiError("Failed to fetch file content (status: \((response as? HTTPURLResponse)?.statusCode ?? 0))")
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw GitHubAuthError.parseError("Failed to decode content as UTF-8")
        }
        
        return content
    }
    
    /// Fetches file content via GitHub API (returns base64 encoded)
    func fetchAPIContent(urlString: String, token: String? = nil) async throws -> String {
        let accessToken = token ?? getAccessTokenFromKeychain() ?? ""
        
        guard !accessToken.isEmpty else {
            throw GitHubAuthError.notAuthenticated
        }
        
        guard let url = URL(string: urlString) else {
            throw GitHubAuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAuthError.apiError("Invalid response from server")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw GitHubAuthError.apiError("File not found")
            }
            throw GitHubAuthError.apiError("Failed to fetch file content (status: \(httpResponse.statusCode))")
        }
        
        // Decode base64 content from API response
        struct FileContent: Codable {
            let content: String
            let encoding: String?
            
            enum CodingKeys: String, CodingKey {
                case content
                case encoding
            }
        }
        
        let fileContent = try JSONDecoder().decode(FileContent.self, from: data)
        
        if fileContent.encoding == "base64" {
            // Clean up base64 string (remove newlines that GitHub adds)
            let cleanBase64 = fileContent.content.replacingOccurrences(of: "\n", with: "")
            
            guard let decodedData = Data(base64Encoded: cleanBase64),
                  let decodedString = String(data: decodedData, encoding: .utf8) else {
                throw GitHubAuthError.parseError("Failed to decode base64 content")
            }
            
            return decodedString
        } else {
            // Sometimes content is returned directly
            return fileContent.content
        }
    }
    
    /// Legacy method - kept for compatibility
    @available(*, deprecated, renamed: "fetchAPIContent")
    func fetchFileContent(urlString: String, token: String? = nil) async throws -> String {
        return try await fetchAPIContent(urlString: urlString, token: token)
    }
    
    /// Detects dependency files in repository root
    func detectDependencyFiles(in repo: GitHubRepository, token: String? = nil) async throws -> [GitHubFile] {
        let files = try await fetchRepoFiles(repo: repo, path: "", token: token)
        
        print("🔍 Raw files from API: \(files.map { $0.name })")
        
        let dependencyFilenames = [
            "package.json",
            "package-lock.json",
            "go.mod",
            "go.sum",
            "Cargo.toml",
            "Cargo.lock",
            "pom.xml",
            "build.gradle",
            "requirements.txt",
            "pyproject.toml",
            "Pipfile",
            "Pipfile.lock",
            "Gemfile",
            "Gemfile.lock",
            "composer.json",
            "composer.lock"
        ]
        
        let filtered = files.filter { file in
            let matches = dependencyFilenames.contains(file.name)
            print("  - \(file.name): \(matches ? "✅ MATCH" : "❌ no match")")
            return matches
        }
        
        print("🔍 Filtered files: \(filtered.map { $0.name })")
        print("🔍 Total files: \(files.count), Filtered: \(filtered.count)")
        
        return filtered
    }
    
    /// Parses dependencies from a manifest file
    func parseDependencies(from file: GitHubFile, token: String? = nil) async throws -> [DetectedDependency] {
        guard let urlString = file.contentUrl else {
            throw GitHubAuthError.parseError("No URL available for file: \(file.name)")
        }
        
        let content: String
        
        // If it's a download URL (raw.githubusercontent.com), fetch directly
        if urlString.contains("raw.githubusercontent.com") {
            content = try await fetchRawContent(urlString: urlString, token: token)
        } else if urlString.contains("api.github.com") {
            // It's an API URL, fetch via API with base64 decoding
            content = try await fetchAPIContent(urlString: urlString, token: token)
        } else {
            // Try as raw URL first, then API
            do {
                content = try await fetchRawContent(urlString: urlString, token: token)
            } catch {
                content = try await fetchAPIContent(urlString: urlString, token: token)
            }
        }
        
        print("📄 Parsing \(file.name) - \(content.count) characters")
        
        switch file.name {
        case "package.json":
            return try parseNPMDependencies(content: content)
        case "go.mod":
            return try parseGoDependencies(content: content)
        case "Cargo.toml":
            return try parseCargoDependencies(content: content)
        case "requirements.txt", "Pipfile":
            return try parsePythonDependencies(content: content)
        case "Gemfile":
            return try parseGemDependencies(content: content)
        case "composer.json":
            return try parseComposerDependencies(content: content)
        default:
            return []
        }
    }
    
    // MARK: - Dependency Parsers
    
    private func parseNPMDependencies(content: String) throws -> [DetectedDependency] {
        struct PackageJSON: Codable {
            let dependencies: [String: String]?
            let devDependencies: [String: String]?
        }
        
        let data = content.data(using: .utf8)!
        let package = try JSONDecoder().decode(PackageJSON.self, from: data)
        
        var deps: [DetectedDependency] = []
        
        if let dependencies = package.dependencies {
            for (name, version) in dependencies {
                deps.append(DetectedDependency(
                    name: name,
                    version: version,
                    ecosystem: .npm,
                    isDev: false
                ))
            }
        }
        
        if let devDeps = package.devDependencies {
            for (name, version) in devDeps {
                deps.append(DetectedDependency(
                    name: name,
                    version: version,
                    ecosystem: .npm,
                    isDev: true
                ))
            }
        }
        
        return deps
    }
    
    private func parseGoDependencies(content: String) throws -> [DetectedDependency] {
        var deps: [DetectedDependency] = []
        let lines = content.components(separatedBy: .newlines)
        
        var inRequire = false
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("require (") {
                inRequire = true
                continue
            }
            if inRequire && line.trimmingCharacters(in: .whitespaces) == ")" {
                inRequire = false
                continue
            }
            
            if inRequire {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.components(separatedBy: .whitespaces)
                if parts.count >= 2 {
                    let name = parts[0]
                    let version = parts[1].replacingOccurrences(of: "v", with: "")
                    deps.append(DetectedDependency(
                        name: name,
                        version: version,
                        ecosystem: .gomod,
                        isDev: false
                    ))
                }
            }
        }
        
        return deps
    }
    
    private func parseCargoDependencies(content: String) throws -> [DetectedDependency] {
        var deps: [DetectedDependency] = []
        let lines = content.components(separatedBy: .newlines)
        
        var inDependencies = false
        for line in lines {
            if line.hasPrefix("[dependencies]") {
                inDependencies = true
                continue
            }
            if line.hasPrefix("[") && line.hasSuffix("]") {
                inDependencies = false
                continue
            }
            
            if inDependencies {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                
                // Simple line parsing (e.g. "serde = \"1.0\"")
                if let equalsRange = trimmed.range(of: "=") {
                    let name = String(trimmed[..<equalsRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let versionPart = String(trimmed[equalsRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    let version = versionPart.replacingOccurrences(of: "\"", with: "")
                    
                    deps.append(DetectedDependency(
                        name: name,
                        version: version,
                        ecosystem: .cargo,
                        isDev: false
                    ))
                }
            }
        }
        
        return deps
    }
    
    private func parsePythonDependencies(content: String) throws -> [DetectedDependency] {
        var deps: [DetectedDependency] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            
            // Parse formats like "requests==2.28.1", "requests>=2.28.1", "requests"
            let separators = ["==", ">=", "<=", ">", "<", "~="]
            
            var name = trimmed
            var version = "latest"
            
            for separator in separators {
                if trimmed.contains(separator) {
                    let parts = trimmed.components(separatedBy: separator)
                    if parts.count >= 2 {
                        name = parts[0].trimmingCharacters(in: .whitespaces)
                        version = parts[1].trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
            }
            
            deps.append(DetectedDependency(
                name: name,
                version: version,
                ecosystem: .pypi,
                isDev: false
            ))
        }
        
        return deps
    }
    
    private func parseGemDependencies(content: String) throws -> [DetectedDependency] {
        var deps: [DetectedDependency] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("gem ") else { continue }
            
            // Parse: gem "rails", "~> 7.0" or gem 'rails', '~> 7.0'
            let withoutPrefix = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
            
            // Handle quoted string
            let quoteChar = withoutPrefix.first
            guard quoteChar == "\"" || quoteChar == "'" else { continue }
            
            let endQuote = withoutPrefix.dropFirst().firstIndex(where: { $0 == quoteChar })
            guard let nameEnd = endQuote else { continue }
            
            let name = String(withoutPrefix[withoutPrefix.index(after: withoutPrefix.startIndex)..<nameEnd])
            
            // Check for version after comma
            var version = "latest"
            let remaining = String(withoutPrefix[nameEnd...]).trimmingCharacters(in: .whitespaces)
            
            if remaining.hasPrefix(","), let commaIndex = remaining.firstIndex(of: ",") {
                let versionPart = String(remaining[remaining.index(after: commaIndex)...])
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "'", with: "")
                    .replacingOccurrences(of: ",", with: "")
                if !versionPart.isEmpty {
                    version = versionPart
                }
            }
            
            deps.append(DetectedDependency(
                name: name,
                version: version,
                ecosystem: .gem,
                isDev: false
            ))
        }
        
        return deps
    }
    
    private func parseComposerDependencies(content: String) throws -> [DetectedDependency] {
        struct ComposerJSON: Codable {
            let require: [String: String]?
            let requireDev: [String: String]?
            
            enum CodingKeys: String, CodingKey {
                case require
                case requireDev = "require-dev"
            }
        }
        
        let data = content.data(using: .utf8)!
        let composer = try JSONDecoder().decode(ComposerJSON.self, from: data)
        
        var deps: [DetectedDependency] = []
        
        if let require = composer.require {
            for (name, version) in require {
                // Skip PHP version require
                guard !name.hasPrefix("php") && !name.hasPrefix("ext-") else { continue }
                deps.append(DetectedDependency(
                    name: name,
                    version: version,
                    ecosystem: .composer,
                    isDev: false
                ))
            }
        }
        
        if let requireDev = composer.requireDev {
            for (name, version) in requireDev {
                deps.append(DetectedDependency(
                    name: name,
                    version: version,
                    ecosystem: .composer,
                    isDev: true
                ))
            }
        }
        
        return deps
    }
    
    // MARK: - User Info
    
    private func fetchAuthenticatedUser(token: String) async throws -> GitHubUser {
        let url = URL(string: "https://api.github.com/user")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubAuthError.apiError("Failed to fetch user")
        }
        
        let user = try JSONDecoder().decode(GitHubUser.self, from: data)
        return user
    }
    
    // MARK: - Keychain Storage
    
    private func saveAccessToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to save token to keychain: \(status)")
        }
    }
    
    func getAccessTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    private func saveUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: usernameKey)
    }
    
    private func clearAuthentication() {
        // Clear keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        
        // Update state
        isAuthenticated = false
        username = nil
    }
    
    // MARK: - Logout
    
    func logout() {
        clearAuthentication()
    }
    
    // MARK: - Helpers
    
    private func generateState() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in letters.randomElement()! })
    }
    
    private func extractCode(from url: URL) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            throw GitHubAuthError.invalidCallback
        }
        
        guard let codeItem = queryItems.first(where: { $0.name == "code" }),
              let code = codeItem.value else {
            throw GitHubAuthError.noAuthCode
        }
        
        return code
    }
}

// MARK: - Repository Metadata Enrichment

extension GitHubAuthService {
    /// Fetches comprehensive metadata for a repository
    func fetchRepoMetadata(repo: GitHubRepository, token: String? = nil) async throws -> RepoMetadata {
        let accessToken = token ?? getAccessTokenFromKeychain() ?? ""
        
        guard !accessToken.isEmpty else {
            throw GitHubAuthError.notAuthenticated
        }
        
        // Fetch repo details
        let repoDetails = try await fetchRepoDetails(repo: repo, token: accessToken)
        
        // Fetch README (first 2000 chars)
        let readme = try? await fetchRepoReadme(repo: repo, token: accessToken)
        
        // Fetch language stats
        let languages = try? await fetchRepoLanguages(repo: repo, token: accessToken)
        
        return RepoMetadata(
            description: repoDetails.description,
            readmeContent: readme?.truncated(to: 2000),
            topics: repoDetails.topics,
            starsCount: repoDetails.stars,
            forksCount: repoDetails.forks,
            license: repoDetails.license?.name,
            lastCommitDate: repoDetails.pushedAt,
            defaultBranch: repoDetails.defaultBranch,
            languageStats: languages
        )
    }
    
    /// Fetches core repository details
    private func fetchRepoDetails(repo: GitHubRepository, token: String) async throws -> GitHubRepoDetails {
        let url = URL(string: "https://api.github.com/repos/\(repo.fullName)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubAuthError.apiError("Failed to fetch repo details")
        }
        
        return try JSONDecoder().decode(GitHubRepoDetails.self, from: data)
    }
    
    /// Fetches README content
    private func fetchRepoReadme(repo: GitHubRepository, token: String) async throws -> String {
        let url = URL(string: "https://api.github.com/repos/\(repo.fullName)/readme")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAuthError.apiError("Invalid response")
        }
        
        if httpResponse.statusCode == 404 {
            return "No README found"
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GitHubAuthError.apiError("Failed to fetch README")
        }
        
        let readmeResponse = try JSONDecoder().decode(GitHubReadmeResponse.self, from: data)
        let cleanBase64 = readmeResponse.content.replacingOccurrences(of: "\n", with: "")
        
        guard let decodedData = Data(base64Encoded: cleanBase64),
              let decodedString = String(data: decodedData, encoding: .utf8) else {
            return "Unable to decode README"
        }
        
        return decodedString
    }
    
    /// Fetches language statistics
    private func fetchRepoLanguages(repo: GitHubRepository, token: String) async throws -> [String: Int] {
        let url = URL(string: "https://api.github.com/repos/\(repo.fullName)/languages")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubAuthError.apiError("Failed to fetch languages")
        }
        
        return try JSONDecoder().decode([String: Int].self, from: data)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GitHubAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .keyWindow ?? UIWindow()
    }
}

// MARK: - Models

struct GitHubUser: Codable {
    let login: String
    let id: Int
    let avatarUrl: String?
    let name: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case login, id, name, email
        case avatarUrl = "avatar_url"
    }
}

struct GitHubRepository: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let updatedAt: String?
    let htmlUrl: String
    let isPrivate: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case stargazersCount = "stargazers_count"
        case updatedAt = "updated_at"
        case htmlUrl = "html_url"
        case isPrivate = "private"
    }
}

struct GitHubFile: Codable, Identifiable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let type: String
    let downloadUrl: String?
    let url: String?  // The API URL for fetching content
    
    var id: String { sha }
    
    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, type, url
        case downloadUrl = "download_url"
    }
    
    /// Gets the best URL to fetch content from
    var contentUrl: String? {
        downloadUrl ?? url
    }
}

struct DetectedDependency: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let ecosystem: EcosystemType
    let isDev: Bool
}

enum EcosystemType: String {
    case npm = "NPM"
    case pypi = "PyPI"
    case gomod = "Go"
    case cargo = "Cargo"
    case maven = "Maven"
    case gradle = "Gradle"
    case gem = "RubyGems"
    case composer = "Composer"
    
    var osvEcosystem: String {
        switch self {
        case .npm: return "npm"
        case .pypi: return "PyPI"
        case .gomod: return "Go"
        case .cargo: return "crates.io"
        case .maven: return "Maven"
        case .gradle: return "Gradle"
        case .gem: return "RubyGems"
        case .composer: return "Packagist"
        }
    }
}

// MARK: - Errors

enum GitHubAuthError: Error, LocalizedError {
    case invalidURL
    case userCancelled
    case noCallback
    case invalidCallback
    case noAuthCode
    case tokenExchangeFailed
    case tokenParseFailed
    case notAuthenticated
    case tokenExpired
    case apiError(String)
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid authentication URL"
        case .userCancelled:
            return "Authentication was cancelled"
        case .noCallback:
            return "No callback received from GitHub"
        case .invalidCallback:
            return "Invalid callback URL"
        case .noAuthCode:
            return "No authorization code in callback"
        case .tokenExchangeFailed:
            return "Failed to exchange code for token"
        case .tokenParseFailed:
            return "Failed to parse authentication response"
        case .notAuthenticated:
            return "Not authenticated with GitHub"
        case .tokenExpired:
            return "Authentication token expired. Please sign in again."
        case .apiError(let message):
            return "GitHub API error: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        }
    }
}

// MARK: - Pull Request Creation (Future)

extension GitHubAuthService {
    /// Creates a fix PR for a dependency (stub for Phase 2)
    func createFixPR(
        repo: GitHubRepository,
        dependency: DetectedDependency,
        newVersion: String
    ) async throws -> GitHubPullRequest {
        // TODO: Implement in Phase 2
        // 1. Create branch
        // 2. Update manifest file
        // 3. Commit changes
        // 4. Create PR
        throw GitHubAuthError.apiError("PR creation not yet implemented")
    }
}

struct GitHubPullRequest: Codable {
    let number: Int
    let title: String
    let htmlUrl: String
    let state: String
}

// MARK: - Repository Metadata Types

/// Repository metadata for AI enrichment
struct RepoMetadata: Codable {
    let description: String?
    let readmeContent: String?
    let topics: [String]?
    let starsCount: Int?
    let forksCount: Int?
    let license: String?
    let lastCommitDate: Date?
    let defaultBranch: String?
    let languageStats: [String: Int]?
}

/// GitHub API response for repo details
struct GitHubRepoDetails: Codable {
    let description: String?
    let topics: [String]?
    let stargazersCount: Int
    let forksCount: Int
    let pushedAt: Date?
    let defaultBranch: String?
    let license: LicenseInfo?
    
    var stars: Int { stargazersCount }
    var forks: Int { forksCount }
    
    enum CodingKeys: String, CodingKey {
        case description
        case topics
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case pushedAt = "pushed_at"
        case defaultBranch = "default_branch"
        case license
    }
}

struct LicenseInfo: Codable {
    let name: String
    let spdxId: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case spdxId = "spdx_id"
    }
}

/// GitHub API response for README
struct GitHubReadmeResponse: Codable {
    let content: String
    let encoding: String
}
