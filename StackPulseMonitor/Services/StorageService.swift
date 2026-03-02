import Foundation

nonisolated final class StorageService: Sendable {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let stackKey = "sp_stack"
    private let projectsKey = "sp_projects"  // New: Project-centric storage
    private let alertsKey = "sp_alerts"
    private let openAIKeyKey = "sp_openai_key"
    private let settingsKey = "sp_settings"
    private let lastSyncKey = "sp_last_sync"
    private let hasOnboardedKey = "sp_has_onboarded"

    private init() {}

    func saveStack(_ stack: [Technology]) {
        if let data = try? encoder.encode(stack) {
            defaults.set(data, forKey: stackKey)
        }
    }

    func loadStack() -> [Technology] {
        guard let data = defaults.data(forKey: stackKey),
              let stack = try? decoder.decode([Technology].self, from: data) else {
            return []
        }
        return stack
    }

    func saveAlerts(_ alerts: [TechAlert]) {
        if let data = try? encoder.encode(alerts) {
            defaults.set(data, forKey: alertsKey)
        }
    }

    func loadAlerts() -> [TechAlert] {
        guard let data = defaults.data(forKey: alertsKey),
              let alerts = try? decoder.decode([TechAlert].self, from: data) else {
            return []
        }
        return alerts
    }

    func saveOpenAIKey(_ key: String) {
        defaults.set(key, forKey: openAIKeyKey)
    }

    func loadOpenAIKey() -> String? {
        defaults.string(forKey: openAIKeyKey)
    }

    func saveLastSync(_ date: Date) {
        defaults.set(date.timeIntervalSince1970, forKey: lastSyncKey)
    }

    func loadLastSync() -> Date? {
        let interval = defaults.double(forKey: lastSyncKey)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    func setHasOnboarded(_ value: Bool) {
        defaults.set(value, forKey: hasOnboardedKey)
    }

    func hasOnboarded() -> Bool {
        defaults.bool(forKey: hasOnboardedKey)
    }

    func hasStack() -> Bool {
        !loadStack().isEmpty || !loadProjects().isEmpty
    }

    func clearAll() {
        defaults.removeObject(forKey: stackKey)
        defaults.removeObject(forKey: alertsKey)
        defaults.removeObject(forKey: openAIKeyKey)
        defaults.removeObject(forKey: settingsKey)
        defaults.removeObject(forKey: lastSyncKey)
        defaults.removeObject(forKey: hasOnboardedKey)
    }

    // MARK: - Project Storage

    func saveProjects(_ projects: [Project]) {
        if let data = try? encoder.encode(projects) {
            defaults.set(data, forKey: projectsKey)
        }
    }

    func loadProjects() -> [Project] {
        guard let data = defaults.data(forKey: projectsKey),
              let projects = try? decoder.decode([Project].self, from: data) else {
            return []
        }
        return projects
    }
}
