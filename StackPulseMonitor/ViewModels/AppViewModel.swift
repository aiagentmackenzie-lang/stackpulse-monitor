import SwiftUI

@Observable
@MainActor
class AppViewModel {
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
        stackItems = storage.loadStack()
        alerts = storage.loadAlerts()
        openAIKey = storage.loadOpenAIKey() ?? ""
        lastSyncTime = storage.loadLastSync()
        hasOnboarded = storage.hasOnboarded()
        hasCompletedSetup = storage.hasStack()
    }

    func saveOpenAIKey(_ key: String) {
        openAIKey = key
        storage.saveOpenAIKey(key)
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

        lastSyncTime = Date()
        storage.saveStack(stackItems)
        storage.saveAlerts(alerts)
        storage.saveLastSync(Date())

        syncProgress = "Sync complete"
        isSyncing = false
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
}
