import Foundation

nonisolated final class NetworkService: Sendable {
    static let shared = NetworkService()
    private init() {}

    func fetchNPMPackage(_ name: String) async throws -> NPMPackageResponse {
        let urlString = "https://registry.npmjs.org/\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name)/latest"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(NPMPackageResponse.self, from: data)
    }

    func searchNPM(_ query: String) async throws -> [NPMSearchPackage] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://registry.npmjs.org/-/v1/search?text=\(encoded)&size=10") else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NPMSearchResponse.self, from: data)
        return response.objects.map(\.package)
    }

    func fetchGitHubRelease(_ repo: String) async throws -> GitHubRelease {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403 {
            throw NetworkError.rateLimited
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    func fetchOSVVulnerabilities(packageName: String, ecosystem: String) async throws -> [OSVVuln] {
        guard let url = URL(string: "https://api.osv.dev/v1/query") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = OSVQueryRequest(package: .init(name: packageName, ecosystem: ecosystem))
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OSVResponse.self, from: data)
        return response.vulns ?? []
    }

    func fetchEOL(_ slug: String) async throws -> [EOLResponse] {
        guard let url = URL(string: "https://endoflife.date/api/\(slug).json") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([EOLResponse].self, from: data)
    }

    func testOpenAIKey(_ key: String) async throws -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        return false
    }

    func fetchAISummary(key: String, tech: Technology) async throws -> AISummaryResult? {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NetworkError.invalidURL
        }

        let cveInfo = tech.vulnerabilities.isEmpty ? "None" : tech.vulnerabilities.map { "\($0.id): \($0.summary) [\($0.severity)]" }.joined(separator: "; ")
        let releaseNotes = String((tech.releaseNotes ?? "None").prefix(500))

        let userPrompt = """
        Tech: \(tech.name) \(tech.currentVersion) → \(tech.latestVersion)
        Release notes: \(releaseNotes)
        CVEs found: \(cveInfo)
        EOL date: \(tech.eolDate ?? "N/A")

        Return JSON only:
        {
          "what_changed": "max 100 chars",
          "is_urgent": "critical|important|minor|none",
          "what_to_do": "max 120 chars",
          "breaking_changes": true/false,
          "score_impact": -10 to 0
        }
        """

        let body = OpenAIChatRequest(
            model: "gpt-4o",
            messages: [
                OpenAIMessage(role: "system", content: "You are a senior software architect. Analyze tech updates concisely. Return valid JSON only."),
                OpenAIMessage(role: "user", content: userPrompt)
            ],
            temperature: 0.3
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)

        guard let content = response.choices?.first?.message?.content else { return nil }

        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanContent.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AISummaryResult.self, from: jsonData)
    }
}

nonisolated enum NetworkError: Error, Sendable, LocalizedError {
    case invalidURL
    case rateLimited
    case decodingError
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .rateLimited: return "Rate limited — retry later"
        case .decodingError: return "Failed to parse response"
        case .serverError(let code): return "Server error (\(code))"
        }
    }
}
