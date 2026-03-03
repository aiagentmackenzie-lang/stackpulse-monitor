import SwiftUI

@Observable
@MainActor
class AppViewModel {
    // MARK: - Project-Centric Model (New)
    var projects: [Project] = []
    
    // MARK: - Legacy Support (Migration)
    var stackItems: [Technology] = []
    var alerts: [TechAlert] = []
    var openAIKey: String = ""
    var lastSyncTime: Date?
    var isSyncing: Bool = false
    var syncProgress: String = ""
    var hasOnboarded: Bool = false
    var hasCompletedSetup: Bool = false
    var isOffline: Bool = false

    private let storage = StorageService.shared
    private let network = NetworkService.shared
    private let alertManager = AlertManager.shared
    
    // MARK: - Computed Properties
    var totalDependencies: Int { projects.reduce(0) { $0 + $1.dependencyCount } }
    var totalOutdated: Int { projects.reduce(0) { $0 + $1.outdatedCount } }

    var healthScore: Int {
        var score = 100
        for item in stackItems {
            switch item.status {
            case .update: score -= 3
            case .critical: score -= 15
            case .eol: score -= 10
            case .unknown: score -= 1
            case .ok: break
            }
            if item.breaking { score -= 5 }
        }
        return max(0, min(100, score))
    }

    var upToDateCount: Int { stackItems.filter { $0.status == .ok }.count }
    var updateCount: Int { stackItems.filter { $0.status == .update }.count }
    var criticalCount: Int { stackItems.filter { $0.status == .critical }.count }
    var activeAlerts: [TechAlert] { alerts.filter { !$0.isDismissed && ($0.snoozedUntil == nil || $0.snoozedUntil! < Date()) } }

    func loadFromStorage() {
        // Load new project-centric data
        projects = storage.loadProjects()
        hasOnboarded = storage.hasOnboarded()
        
        // Legacy support: migrate old stack ONLY on first launch (never after deletion)
        // Check: has user completed setup before? If yes, don't recreate deleted projects
        if projects.isEmpty && !hasOnboarded {
            let legacyStack = storage.loadStack()
            if !legacyStack.isEmpty {
                migrateLegacyStack(legacyStack)
            }
        }
        
        alerts = storage.loadAlerts()
        openAIKey = storage.loadOpenAIKey() ?? ""
        lastSyncTime = storage.loadLastSync()
        hasCompletedSetup = !projects.isEmpty || hasOnboarded
    }
    
    private func migrateLegacyStack(_ legacy: [Technology]) {
        // Group legacy items by source/repo
        let grouped = Dictionary(grouping: legacy) { tech in
            if tech.type == .github {
                return tech.name
            }
            return "Legacy Imports"
        }
        
        for (name, items) in grouped {
            var project = Project(
                name: name,
                source: items.first?.type == .github ? .github : .manual
            )
            
            if items.first?.type == .github {
                project.githubFullName = items.first?.identifier
            }
            
            // Convert Technologies to Dependencies
            project.dependencies = items.compactMap { tech in
                guard tech.type != .github else { return nil } // Skip the repo itself
                return Dependency(
                    name: tech.name,
                    type: tech.type,
                    category: tech.category,
                    currentVersion: tech.currentVersion,
                    latestVersion: tech.latestVersion
                )
            }
            
            projects.append(project)
        }
        
        storage.saveProjects(projects)
    }

    func saveOpenAIKey(_ key: String) {
        openAIKey = key
        storage.saveOpenAIKey(key)
    }

    func persistProjects() {
        storage.saveProjects(projects)
    }

    func completeOnboarding() {
        hasOnboarded = true
        storage.setHasOnboarded(true)
    }

    func addTechnology(_ tech: Technology) {
        stackItems.append(tech)
        storage.saveStack(stackItems)
    }

    func removeTechnology(_ tech: Technology) {
        stackItems.removeAll { $0.id == tech.id }
        alerts.removeAll { $0.techId == tech.id }
        storage.saveStack(stackItems)
        storage.saveAlerts(alerts)
    }

    func updateVersion(for techId: UUID, version: String) {
        if let index = stackItems.firstIndex(where: { $0.id == techId }) {
            stackItems[index].currentVersion = version
            storage.saveStack(stackItems)
        }
    }

    func dismissAlert(_ alert: TechAlert) {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index].isDismissed = true
            storage.saveAlerts(alerts)
        }
    }

    func snoozeAlert(_ alert: TechAlert, days: Int) {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index].snoozedUntil = Calendar.current.date(byAdding: .day, value: days, to: Date())
            storage.saveAlerts(alerts)
        }
    }

    func completeSetup() {
        hasCompletedSetup = true
        storage.saveStack(stackItems)
    }

    func syncStack() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncProgress = "Syncing \(stackItems.count) items..."

        var newAlerts: [TechAlert] = []

        for i in stackItems.indices {
            let tech = stackItems[i]
            syncProgress = "Checking \(tech.name)..."

            var updated = tech

            do {
                if tech.type == .npm || (tech.type == .platform && !tech.identifier.contains("/")) {
                    if let npmName = npmIdentifier(for: tech) {
                        let npmResponse = try await network.fetchNPMPackage(npmName)
                        if let latest = npmResponse.version {
                            updated.latestVersion = latest
                        }
                    }
                }
            } catch {
                // Use cached data
            }

            if tech.type == .github && tech.identifier.contains("/") {
                do {
                    let release = try await network.fetchGitHubRelease(tech.identifier)
                    updated.latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                    updated.releaseNotes = release.body
                } catch {
                    // Use cached data
                }
            }

            do {
                let ecosystem = tech.type == .npm ? "npm" : "PyPI"
                let vulns = try await network.fetchOSVVulnerabilities(
                    packageName: tech.identifier,
                    ecosystem: ecosystem
                )
                updated.vulnerabilities = vulns.prefix(5).map { vuln in
                    let severity = vuln.severity?.first?.score ?? "UNKNOWN"
                    let fixed = vuln.affected?.first?.ranges?.first?.events?.first(where: { $0.fixed != nil })?.fixed
                    return Vulnerability(
                        id: vuln.id,
                        summary: vuln.summary ?? "No description",
                        severity: severity,
                        publishedDate: vuln.published,
                        fixedVersion: fixed
                    )
                }
            } catch {
                // CVE check unavailable
            }

            let preset = PresetTech.all.first { $0.name.lowercased() == tech.name.lowercased() }
            if let eolSlug = preset?.eolSlug {
                do {
                    let eolData = try await network.fetchEOL(eolSlug)
                    if let first = eolData.first {
                        if case .string(let dateStr) = first.eol {
                            updated.eolDate = dateStr
                        } else if case .bool(let isEol) = first.eol, isEol {
                            updated.eolDate = "Already EOL"
                        }
                    }
                } catch {
                    // EOL check unavailable
                }
            }

            updated.status = determineStatus(updated)
            updated.lastChecked = Date()

            if !openAIKey.isEmpty {
                do {
                    if let summary = try await network.fetchAISummary(key: openAIKey, tech: updated) {
                        var parts: [String] = []
                        if let changed = summary.what_changed, !changed.isEmpty {
                            parts.append(changed)
                        }
                        if let urgent = summary.is_urgent, !urgent.isEmpty {
                            parts.append("Urgency: \(urgent)")
                        }
                        if let todo = summary.what_to_do, !todo.isEmpty {
                            parts.append(todo)
                        }
                        updated.aiSummary = parts.joined(separator: " · ")
                        updated.breaking = summary.breaking_changes ?? false
                    }
                } catch {
                    // AI unavailable
                }
            }

            stackItems[i] = updated

            if !updated.vulnerabilities.isEmpty {
                newAlerts.append(TechAlert(
                    techId: updated.id,
                    techName: updated.name,
                    type: .critical,
                    title: "CVE Found in \(updated.name)",
                    message: updated.vulnerabilities.first?.summary ?? "Vulnerability detected",
                    severity: updated.vulnerabilities.first?.severity ?? "UNKNOWN"
                ))
            }

            if updated.status == .update && !updated.latestVersion.isEmpty {
                let isMajor = isMajorUpdate(current: updated.currentVersion, latest: updated.latestVersion)
                if isMajor {
                    newAlerts.append(TechAlert(
                        techId: updated.id,
                        techName: updated.name,
                        type: .update,
                        title: "Major Update: \(updated.name)",
                        message: "\(updated.currentVersion) → \(updated.latestVersion)",
                        severity: "MEDIUM"
                    ))
                }
            }

            if updated.eolDate != nil {
                newAlerts.append(TechAlert(
                    techId: updated.id,
                    techName: updated.name,
                    type: .eol,
                    title: "EOL Warning: \(updated.name)",
                    message: "End of Life: \(updated.eolDate ?? "Unknown")",
                    severity: "LOW"
                ))
            }
        }

        let existingDismissed = Set(alerts.filter(\.isDismissed).map { "\($0.techId)-\($0.type)" })
        alerts = newAlerts.map { alert in
            var a = alert
            let key = "\(a.techId)-\(a.type)"
            if existingDismissed.contains(key) {
                a.isDismissed = true
            }
            return a
        }
        
        // Process alerts through AlertManager for notifications
        alertManager.processAlerts(newAlerts)

        lastSyncTime = Date()
        storage.saveStack(stackItems)
        storage.saveAlerts(alerts)
        storage.saveLastSync(Date())

        syncProgress = "Sync complete"
        isSyncing = false
    }

    // MARK: - Alert Notifications
    
    /// Check and request notification permissions
    func checkNotificationPermissions() async -> Bool {
        await alertManager.checkPermissionStatus()
        if !alertManager.hasPermission {
            return await alertManager.requestPermission()
        }
        return alertManager.hasPermission
    }
    
    /// Request notification permissions explicitly
    func requestNotificationPermissions() async -> Bool {
        return await alertManager.requestPermission()
    }
    
    /// Clear notification badge
    func clearNotificationBadge() {
        alertManager.clearBadge()
    }
    
    func clearAllData() {
        stackItems = []
        alerts = []
        openAIKey = ""
        lastSyncTime = nil
        hasOnboarded = false
        hasCompletedSetup = false
        storage.clearAll()
    }

    private func npmIdentifier(for tech: Technology) -> String? {
        if tech.type == .npm { return tech.identifier }
        let mapping: [String: String] = [
            "node.js": "node", "python": "python", "go": "go", "rust": "rust"
        ]
        return mapping[tech.name.lowercased()]
    }

    private func determineStatus(_ tech: Technology) -> TechStatus {
        if !tech.vulnerabilities.isEmpty { return .critical }
        if tech.eolDate == "Already EOL" { return .eol }
        if !tech.currentVersion.isEmpty && !tech.latestVersion.isEmpty {
            if tech.currentVersion == tech.latestVersion { return .ok }
            return .update
        }
        if !tech.latestVersion.isEmpty && tech.currentVersion.isEmpty { return .update }
        return .unknown
    }

    private func isMajorUpdate(current: String, latest: String) -> Bool {
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        guard let cMajor = currentParts.first, let lMajor = latestParts.first else { return false }
        return lMajor > cMajor
    }
    
    // MARK: - Project Management
    
    func addProject(_ project: Project) {
        projects.append(project)
        storage.saveProjects(projects)
    }
    
    func removeProject(_ project: Project, deleteDependencies: Bool = true) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            if deleteDependencies {
                // Dependencies are part of project, so they auto-delete
                projects.remove(at: index)
            } else {
                // Orphan dependencies - convert to manual project
                var orphaned = project
                orphaned.source = .manual
                orphaned.githubFullName = nil
                orphaned.dependencies = []
                projects.remove(at: index)
                projects.append(orphaned)
            }
            storage.saveProjects(projects)
            // Force immediate write before app can be backgrounded
            Task {
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
    
    func addDependency(_ dependency: Dependency, to projectId: UUID) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].dependencies.append(dependency)
            storage.saveProjects(projects)
        }
    }
    
    func removeDependency(_ dependencyId: UUID, from projectId: UUID) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].dependencies.removeAll { $0.id == dependencyId }
            storage.saveProjects(projects)
        }
    }
    
    func toggleProjectExpansion(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isExpanded.toggle()
        }
    }
    
    // MARK: - Version Checking
    
    /// Update a single dependency's latest version and persist
    func updateDependency(
        projectId: UUID,
        dependencyId: UUID,
        latestVersion: String,
        isOutdated: Bool
    ) {
        if let projectIndex = projects.firstIndex(where: { $0.id == projectId }),
           let depIndex = projects[projectIndex].dependencies.firstIndex(where: { $0.id == dependencyId }) {
            
            projects[projectIndex].dependencies[depIndex].latestVersion = latestVersion
            projects[projectIndex].dependencies[depIndex].isOutdated = isOutdated
            projects[projectIndex].dependencies[depIndex].lastChecked = Date()
            
            storage.saveProjects(projects)
        }
    }
    
    /// Check versions for all dependencies in a project
    func checkVersions(forProjectId projectId: UUID) async {
        let service = VersionCheckService.shared
        
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else {
            return
        }
        
        let deps = projects[projectIndex].dependencies
        
        for dep in deps {
            if let latest = await service.checkVersion(dep) {
                let isOutdated = !dep.currentVersion.isEmpty && dep.currentVersion != latest
                
                await MainActor.run {
                    updateDependency(
                        projectId: projectId,
                        dependencyId: dep.id,
                        latestVersion: latest,
                        isOutdated: isOutdated
                    )
                }
            }
        }
    }
    
    // MARK: - AI Analysis
    
    /// Generate AI-powered analysis report for a project
    func generateAIReport(for projectId: UUID) async throws -> ProjectAIReport? {
        let network = NetworkService.shared
        
        guard let project = projects.first(where: { $0.id == projectId }) else {
            return nil
        }
        
        // Get outdated dependencies with known latest versions
        let outdatedDeps = project.dependencies.filter { dep in
            dep.isOutdated && dep.latestVersion != nil
        }
        
        guard !outdatedDeps.isEmpty else {
            return nil // No outdated deps to analyze
        }
        
        // Get CVE data for each dependency
        var cveData: [String: [String]] = [:]
        for dep in outdatedDeps {
            do {
                let vulns = try await network.fetchOSVVulnerabilities(
                    packageName: dep.name,
                    ecosystem: dep.type.rawValue
                )
                cveData[dep.name] = vulns.map { $0.id }
            } catch {
                cveData[dep.name] = []
            }
        }
        
        // Build dependency context
        let depContexts: [AIDependencyContext] = outdatedDeps.map { dep in
            AIDependencyContext(
                name: dep.name,
                currentVersion: dep.currentVersion,
                latestVersion: dep.latestVersion ?? dep.currentVersion,
                type: dep.type.rawValue,
                category: dep.category.rawValue,
                changelogSnippet: nil, // Could fetch from GitHub releases
                cveCount: cveData[dep.name]?.count ?? 0
            )
        }
        
        // Build request
        let request = AIProjectAnalysisRequest(
            projectName: project.name,
            dependencies: depContexts,
            cveData: cveData,
            currentStack: depContexts.map { "\($0.name)@\($0.currentVersion)" }.joined(separator: ", ")
        )
        
        // Call OpenAI
        guard !openAIKey.isEmpty else {
            throw AIError.noAPIKey
        }
        
        let report = try await fetchAIProjectAnalysis(request: request, key: openAIKey)
        
        // Save report to project
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].aiReports.append(report)
            persistProjects()
        }
        
        return report
    }
    
    private func fetchAIProjectAnalysis(request: AIProjectAnalysisRequest, key: String) async throws -> ProjectAIReport {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIError.invalidURL
        }
        
        let userPrompt = """
        Analyze these outdated dependencies for project "\(request.projectName)":
        
        Stack: \(request.currentStack)
        
        Dependencies to analyze:
        \(request.dependencies.map { dep in
            "- \(dep.name): \(dep.currentVersion) → \(dep.latestVersion) (\(dep.category), \(dep.type), \(dep.cveCount) CVEs)"
        }.joined(separator: "\n"))
        
        CVEs:
        \(request.cveData.map { "\($0.key): \($0.value.joined(separator: ", "))" }.joined(separator: "\n"))
        
        Return a JSON analysis with:
        {
          "summary": "Brief summary of update status",
          "critical": [array of critical updates with security issues],
          "safe": [array of safe, low-risk updates],
          "review": [array of updates needing review],
          "actionPlan": [prioritized list of steps],
          "estimatedTime": "estimated time to complete",
          "overallRiskScore": 0-100 (higher = more risky)
        }
        
        For each dependency in critical/safe/review arrays, include:
        {
          "dependencyName": "name",
          "riskLevel": "Critical|Important|Recommended|Optional",
          "reason": "Why this classification",
          "breakingChanges": true/false,
          "securityImpact": "CVE details or null",
          "migrationComplexity": "Simple|Moderate|Complex",
          "recommendedAction": "Specific action to take"
        }
        """
        
        let body = OpenAIChatRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: "You are a senior software architect. Analyze dependency updates and return valid JSON only. Be concise and actionable."),
                OpenAIMessage(role: "user", content: userPrompt)
            ],
            temperature: 0.3
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.apiError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = chatResponse.choices?.first?.message?.content else {
            throw AIError.noContent
        }
        
        // Parse the JSON from content
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanContent.data(using: .utf8),
              let aiResponse = try? JSONDecoder().decode(AIProjectAnalysisResponse.self, from: jsonData) else {
            throw AIError.decodingFailed
        }
        
        // Convert to ProjectAIReport
        return ProjectAIReport(
            projectId: request.dependencies.first.flatMap { _ in UUID() } ?? UUID(),
            summary: aiResponse.summary,
            criticalUpdates: aiResponse.critical.map { mapAIInsight($0) },
            safeUpdates: aiResponse.safe.map { mapAIInsight($0) },
            reviewRecommended: aiResponse.review.map { mapAIInsight($0) },
            actionPlan: aiResponse.actionPlan,
            estimatedTime: aiResponse.estimatedTime,
            overallRiskScore: aiResponse.overallRiskScore
        )
    }
    
    private func mapAIInsight(_ raw: AIInsightRaw) -> AIDependencyInsight {
        AIDependencyInsight(
            dependencyName: raw.dependencyName,
            currentVersion: "", // Will be looked up from project
            latestVersion: "",
            riskLevel: UpdateRiskLevel(rawValue: raw.riskLevel) ?? .optional,
            reason: raw.reason,
            breakingChanges: raw.breakingChanges,
            securityImpact: raw.securityImpact,
            migrationComplexity: Complexity(rawValue: raw.migrationComplexity) ?? .simple,
            recommendedAction: raw.recommendedAction
        )
    }
}

enum AIError: Error {
    case noAPIKey
    case invalidURL
    case apiError(String)
    case noContent
    case decodingFailed
}

