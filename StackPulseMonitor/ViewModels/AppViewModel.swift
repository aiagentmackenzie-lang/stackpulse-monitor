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
        // Use projects (new model) instead of stackItems (legacy)
        for project in projects {
            for dep in project.dependencies {
                if dep.isOutdated {
                    score -= 3
                } else if dep.currentVersion.isEmpty && dep.latestVersion != nil {
                    score -= 3
                } else if dep.currentVersion.isEmpty {
                    score -= 1
                }
                // .ok and up-to-date: no penalty
            }
        }
        return max(0, min(100, score))
    }

    var upToDateCount: Int { 
        projects.flatMap { $0.dependencies }.filter { !$0.isOutdated && !$0.currentVersion.isEmpty }.count 
    }
    var updateCount: Int { 
        projects.flatMap { $0.dependencies }.filter { $0.isOutdated }.count 
    }
    var criticalCount: Int { 
        0 // Dependency doesn't track vulnerabilities, always 0
    }
    var activeAlerts: [TechAlert] { alerts.filter { !$0.isDismissed && ($0.snoozedUntil == nil || $0.snoozedUntil! < Date()) } }
    
    /// Alerts that haven't been read yet (for badge)
    var unreadAlerts: [TechAlert] { 
        activeAlerts.filter { !$0.isRead } 
    }

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

    func saveStack() {
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
            // Cancel notification for dismissed alert
            alertManager.cancelNotification(for: alert.id)
        }
    }

    func snoozeAlert(_ alert: TechAlert, days: Int) {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index].snoozedUntil = Calendar.current.date(byAdding: .day, value: days, to: Date())
            storage.saveAlerts(alerts)
            // Cancel notification for snoozed alert
            alertManager.cancelNotification(for: alert.id)
        }
    }

    /// Permanently delete an alert from the array
    func deleteAlert(_ alert: TechAlert) {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts.remove(at: index)
            storage.saveAlerts(alerts)
            // Cancel notification for deleted alert
            alertManager.cancelNotification(for: alert.id)
        }
    }

    // MARK: - Alert Reading

    /// Mark a specific alert as read and cancel its notification
    func markAlertAsRead(_ alertId: UUID) {
        guard let index = alerts.firstIndex(where: { $0.id == alertId }) else {
            return
        }
        
        // Update alert
        alerts[index].isRead = true
        alerts[index].readAt = Date()
        storage.saveAlerts(alerts)
        
        // Cancel delivered notification
        alertManager.cancelNotification(for: alertId)
    }

    /// Mark all active alerts as read and clear notifications
    func markAllAlertsAsRead() {
        // Mark ALL alerts as read (not just active ones)
        for index in alerts.indices {
            if !alerts[index].isRead {
                alerts[index].isRead = true
                alerts[index].readAt = Date()
            }
            // Cancel notification for this alert
            alertManager.cancelNotification(for: alerts[index].id)
        }
        
        // Also clear any orphaned notifications (notifications for alerts that no longer exist)
        alertManager.cancelAllNotifications()
        
        // Save changes
        storage.saveAlerts(alerts)
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
        
        // Update app badge with active alerts count (async, fire-and-forget)
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(newAlerts.filter { !$0.isDismissed }.count)
        }

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

    /// Clear all notifications
    func clearAllNotifications() {
        alertManager.cancelAllNotifications()
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
        print("🔍 checkVersions START for project: \(projectId)")
        let service = VersionCheckService.shared
        
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else {
            print("❌ Project not found: \(projectId)")
            return
        }
        
        let deps = projects[projectIndex].dependencies
        print("📋 Found \(deps.count) dependencies to check")
        
        for dep in deps {
            print("⏳ Checking \(dep.name) (type: \(dep.type.rawValue), current: \(dep.currentVersion))")
            if let latest = await service.checkVersion(dep) {
                print("✅ Got version for \(dep.name): \(latest)")
                let isOutdated = !dep.currentVersion.isEmpty && dep.currentVersion != latest
                
                await MainActor.run {
                    updateDependency(
                        projectId: projectId,
                        dependencyId: dep.id,
                        latestVersion: latest,
                        isOutdated: isOutdated
                    )
                }
            } else {
                print("⚠️ No version returned for \(dep.name)")
            }
        }
        
        print("🔍 checkVersions END")
        // Generate alerts after checking versions
        await checkProjectForAlerts(projectId: projectId)
    }
    
    // MARK: - Project Alert Checking
    
    /// Check a project for alerts (CVEs, updates, EOL) and generate TechAlerts
    func checkProjectForAlerts(projectId: UUID) async {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else {
            return
        }
        
        var newAlerts: [TechAlert] = []
        let deps = projects[projectIndex].dependencies
        
        for dep in deps {
            // Skip dependencies without known versions
            guard !dep.currentVersion.isEmpty else { continue }
            
            // Check for CVEs (vulnerabilities)
            do {
                let vulns = try await network.fetchOSVVulnerabilities(
                    packageName: dep.name,
                    ecosystem: dep.type.rawValue
                )
                
                if !vulns.isEmpty {
                    let severity = vulns.first?.severity?.first?.score ?? "UNKNOWN"
                    newAlerts.append(TechAlert(
                        techId: dep.id,
                        techName: dep.name,
                        type: .critical,
                        title: "CVE Found in \(dep.name)",
                        message: vulns.first?.summary ?? "Vulnerability detected",
                        severity: severity
                    ))
                }
            } catch {
                // CVE check unavailable
            }
            
            // Check for updates
            if let latest = dep.latestVersion, dep.isOutdated {
                let isMajor = isMajorUpdate(current: dep.currentVersion, latest: latest)
                if isMajor {
                    newAlerts.append(TechAlert(
                        techId: dep.id,
                        techName: dep.name,
                        type: .update,
                        title: "Major Update: \(dep.name)",
                        message: "\(dep.currentVersion) → \(latest)",
                        severity: "MEDIUM"
                    ))
                }
            }
            
            // Check for EOL
            let preset = PresetTech.all.first { $0.name.lowercased() == dep.name.lowercased() }
            if let eolSlug = preset?.eolSlug {
                do {
                    let eolData = try await network.fetchEOL(eolSlug)
                    if let first = eolData.first {
                        if case .string(let dateStr) = first.eol {
                            newAlerts.append(TechAlert(
                                techId: dep.id,
                                techName: dep.name,
                                type: .eol,
                                title: "EOL Warning: \(dep.name)",
                                message: "End of Life: \(dateStr)",
                                severity: "LOW"
                            ))
                        } else if case .bool(let isEol) = first.eol, isEol {
                            newAlerts.append(TechAlert(
                                techId: dep.id,
                                techName: dep.name,
                                type: .eol,
                                title: "EOL Warning: \(dep.name)",
                                message: "Already End of Life",
                                severity: "LOW"
                            ))
                        }
                    }
                } catch {
                    // EOL check unavailable
                }
            }
        }
        
        // Merge new alerts, preserving dismissed state
        let existingDismissed = Set(alerts.filter(\.isDismissed).map { "\($0.techId)-\($0.type)" })
        let mergedAlerts = newAlerts.map { alert in
            var a = alert
            let key = "\(a.techId)-\(a.type)"
            if existingDismissed.contains(key) {
                a.isDismissed = true
            }
            return a
        }
        
        // Add to existing alerts (replace any for same tech+type)
        var alertMap = Dictionary(uniqueKeysWithValues: alerts.map { ("\($0.techId)-\($0.type)", $0) })
        for alert in mergedAlerts {
            alertMap["\(alert.techId)-\(alert.type)"] = alert
        }
        alerts = Array(alertMap.values)
        
        // Process through AlertManager for notifications
        alertManager.processAlerts(mergedAlerts, forProject: projectId)
        
        // Save alerts
        storage.saveAlerts(alerts)
        
        // Update badge
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(activeAlerts.count)
        }
    }
    
    /// Check all projects for alerts
    func checkAllProjectsForAlerts() async {
        for project in projects {
            await checkProjectForAlerts(projectId: project.id)
        }
    }
    
    // MARK: - Navigation Helpers
    
    /// Find the project containing a specific dependency/technology
    func findProject(forTechId techId: UUID) -> Project? {
        // Search in project dependencies first (new model)
        if let project = projects.first(where: { project in
            project.dependencies.contains { $0.id == techId }
        }) {
            return project
        }
        
        // Legacy: check if techId matches a project's dependency name
        // This handles alerts for dependencies that might not be in the new model yet
        return nil
    }
    
    /// Get dependency details for a given techId
    func getDependency(forTechId techId: UUID) -> Dependency? {
        for project in projects {
            if let dep = project.dependencies.first(where: { $0.id == techId }) {
                return dep
            }
        }
        return nil
    }
    
    // MARK: - AI Analysis
    
    /// Generate AI-powered analysis report for a project
    func generateAIReport(for projectId: UUID) async throws -> ProjectAIReport? {
        let network = NetworkService.shared
        
        guard let project = projects.first(where: { $0.id == projectId }) else {
            return nil
        }
        
        // Get ALL dependencies, not just outdated ones
        let allDeps = project.dependencies
        
        guard !allDeps.isEmpty else {
            throw AIError.noDependenciesToAnalyze
        }
        
        // Separate outdated from up-to-date
        let outdatedDeps = allDeps.filter { dep in
            dep.isOutdated && dep.latestVersion != nil
        }
        let upToDateDeps = allDeps.filter { dep in
            !dep.isOutdated && dep.latestVersion != nil
        }
        let uncheckedDeps = allDeps.filter { dep in
            dep.latestVersion == nil
        }
        
        // Get CVE data for each dependency (both outdated and up-to-date)
        var cveData: [String: [String]] = [:]
        for dep in allDeps {
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
        
        // Build dependency context for ALL deps
        let depContexts: [AIDependencyContext] = allDeps.map { dep in
            AIDependencyContext(
                name: dep.name,
                currentVersion: dep.currentVersion,
                latestVersion: dep.latestVersion ?? dep.currentVersion,
                type: dep.type.rawValue,
                category: dep.category.rawValue,
                changelogSnippet: nil,
                cveCount: cveData[dep.name]?.count ?? 0
            )
        }
        
        // Build request with full context
        let request = AIProjectAnalysisRequest(
            projectName: project.name,
            dependencies: depContexts,
            outdatedCount: outdatedDeps.count,
            upToDateCount: upToDateDeps.count,
            uncheckedCount: uncheckedDeps.count,
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
        Analyze dependency health for project "\(request.projectName)":
        
        Summary: \(request.outdatedCount) outdated, \(request.upToDateCount) up-to-date, \(request.uncheckedCount) unchecked
        
        Dependencies to analyze:
        \(request.dependencies.map { dep in
            let status: String
            if dep.currentVersion == dep.latestVersion {
                status = "✅ UP TO DATE"
            } else if dep.cveCount > 0 {
                status = "⚠️ OUTDATED (\(dep.cveCount) CVEs)"
            } else {
                status = "📦 OUTDATED"
            }
            return "- \(dep.name): \(dep.currentVersion) → \(dep.latestVersion) [\(status), \(dep.category), \(dep.type)]"
        }.joined(separator: "\n"))
        
        Unchecked dependencies (no version data available):
        \(request.dependencies.filter { $0.currentVersion == $0.latestVersion && $0.cveCount == 0 }.map { "- \($0.name) (\($0.type))" }.joined(separator: "\n"))
        
        CVEs found:
        \(request.cveData.filter { !$0.value.isEmpty }.map { "- \($0.key): \($0.value.joined(separator: ", "))" }.joined(separator: "\n"))
        
        Return valid JSON only:
        {
          "summary": "Brief summary: health status, update needs, and unchecked items",
          "critical": [dependencies that MUST be updated - security CVEs, major versions behind],
          "safe": [dependencies that SHOULD be updated - minor/patch updates, no breaking changes expected],
          "review": [dependencies that NEED REVIEW - breaking changes possible, custom code impacts],
          "actionPlan": [prioritized steps to improve health],
          "estimatedTime": "estimated time for all updates",
          "overallRiskScore": 0-100 (higher = more risky to NOT update)
        }
        
        For each dependency:
        {
          "dependencyName": "name",
          "riskLevel": "Critical|Important|Recommended|Optional",
          "reason": "Why this classification",
          "breakingChanges": true/false,
          "securityImpact": "CVE details or null",
          "migrationComplexity": "Simple|Moderate|Complex",
          "recommendedAction": "Specific next step"
        }
        
        If all dependencies are up-to-date, set overallRiskScore to 0 and actionPlan to ["All dependencies are current. No action needed."]
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
    case noDependenciesToAnalyze
}

