import Foundation

/// Checks package registries for latest versions
@MainActor
class VersionCheckService {
    static let shared = VersionCheckService()
    private init() {}
    
    /// Rate limiter: max 5 requests per second
    private let rateLimiter = RateLimiter(maxRequests: 5, perSeconds: 1)
    
    /// Cache: check results valid for 24 hours
    private let cacheTTL: TimeInterval = 86400
    
    /// Check version for a single dependency
    func checkVersion(_ dependency: Dependency) async -> String? {
        print("[VersionCheck] Checking \(dependency.name) (type: \(dependency.type.rawValue))")
        
        switch dependency.type {
        case .npm:
            return await checkNPM(name: dependency.name)
        case .pypi:
            return await checkPyPI(name: dependency.name)
        case .cargo:
            return await checkCargo(name: dependency.name)
        case .gem:
            return await checkGem(name: dependency.name)
        case .platform:
            return await checkPlatform(name: dependency.name)
        default:
            print("[VersionCheck] ⚠️ Unsupported type: \(dependency.type) for \(dependency.name)")
            return nil
        }
    }
    
    /// Validate all registry endpoints work (for diagnostics)
    func validateRegistries() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Test NPM with known package
        if let npm = await checkNPM(name: "express") {
            results["NPM"] = !npm.isEmpty
            print("[Validate] NPM ✓ (express@\(npm))")
        } else {
            results["NPM"] = false
            print("[Validate] NPM ✗")
        }
        
        // Test PyPI with known package
        if let pypi = await checkPyPI(name: "requests") {
            results["PyPI"] = !pypi.isEmpty
            print("[Validate] PyPI ✓ (requests@\(pypi))")
        } else {
            results["PyPI"] = false
            print("[Validate] PyPI ✗")
        }
        
        // Test Cargo with known crate
        if let cargo = await checkCargo(name: "serde") {
            results["Cargo"] = !cargo.isEmpty
            print("[Validate] Cargo ✓ (serde@\(cargo))")
        } else {
            results["Cargo"] = false
            print("[Validate] Cargo ✗")
        }
        
        // Test RubyGems with known gem
        if let gem = await checkGem(name: "rails") {
            results["RubyGems"] = !gem.isEmpty
            print("[Validate] RubyGems ✓ (rails@\(gem))")
        } else {
            results["RubyGems"] = false
            print("[Validate] RubyGems ✗")
        }
        
        return results
    }
    
    /// Check multiple dependencies with rate limiting
    func checkVersions(_ dependencies: [Dependency]) async -> [UUID: String] {
        var results: [UUID: String] = [:]
        
        for dep in dependencies {
            await rateLimiter.wait()
            
            if let latest = await checkVersion(dep) {
                results[dep.id] = latest
            }
        }
        
        return results
    }
    
    // MARK: - NPM Registry
    
    private func checkNPM(name: String) async -> String? {
        let cleanName = name.replacingOccurrences(of: "\n", with: "")
        let url = URL(string: "https://registry.npmjs.org/\(cleanName)/latest")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(NPMResponse.self, from: data)
            return response.version
        } catch {
            print("❌ NPM check failed for \(name): \(error)")
            return nil
        }
    }
    
    struct NPMResponse: Codable {
        let version: String
    }
    
    // MARK: - PyPI Registry
    
    private func checkPyPI(name: String) async -> String? {
        let cleanName = name.replacingOccurrences(of: "\n", with: "")
        let url = URL(string: "https://pypi.org/pypi/\(cleanName)/json")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PyPIResponse.self, from: data)
            return response.info.version
        } catch {
            print("❌ PyPI check failed for \(name): \(error)")
            return nil
        }
    }
    
    struct PyPIResponse: Codable {
        let info: PyPIInfo
        struct PyPIInfo: Codable {
            let version: String
        }
    }
    
    // MARK: - RubyGems
    
    private func checkGem(name: String) async -> String? {
        let cleanName = name.replacingOccurrences(of: "\n", with: ":")
        let url = URL(string: "https://rubygems.org/api/v1/gems/\(cleanName).json")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GemResponse.self, from: data)
            return response.version
        } catch {
            print("❌ RubyGems check failed for \(name): \(error)")
            return nil
        }
    }
    
    struct GemResponse: Codable {
        let version: String
    }
    
    // MARK: - Cargo/Crates.io
    
    private func checkCargo(name: String) async -> String? {
        let cleanName = name.replacingOccurrences(of: "\n", with: "")
        let url = URL(string: "https://crates.io/api/v1/crates/\(cleanName)")!
        
        do {
            var request = URLRequest(url: url)
            request.setValue("StackPulse/1.0", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CargoResponse.self, from: data)
            return response.crate.newest_version
        } catch {
            print("❌ Cargo check failed for \(name): \(error)")
            return nil
        }
    }
    
    struct CargoResponse: Codable {
        let crate: CargoCrate
        struct CargoCrate: Codable {
            let newest_version: String
        }
    }
    
    // MARK: - Platform Types (map to appropriate registries)
    
    private func checkPlatform(name: String) async -> String? {
        // Map platform identifiers to their package registry equivalents
        // Note: name here is the identifier (lowercase), not the display name
        let platformMappings: [String: (registry: String, package: String)] = [
            "django": ("pypi", "Django"),  // PyPI needs capital D for Django
            "fastapi": ("pypi", "fastapi"),
            "laravel": ("pypi", "laravel"),  // Note: Laravel is PHP, may not be on PyPI
        ]
        
        if let mapping = platformMappings[name] {
            print("[VersionCheck] Mapped platform '\(name)' to \(mapping.registry) package '\(mapping.package)'")
            switch mapping.registry {
            case "npm":
                return await checkNPM(name: mapping.package)
            case "pypi":
                return await checkPyPI(name: mapping.package)
            default:
                return nil
            }
        }
        
        print("[VersionCheck] No registry mapping for platform: \(name)")
        return nil
    }
}

/// Simple rate limiter
@MainActor
class RateLimiter {
    private let maxRequests: Int
    private let interval: TimeInterval
    private var timestamps: [Date] = []
    
    init(maxRequests: Int, perSeconds: TimeInterval) {
        self.maxRequests = maxRequests
        self.interval = perSeconds
    }
    
    func wait() async {
        let now = Date()
        timestamps.removeAll { now.timeIntervalSince($0) > interval }
        
        if timestamps.count >= maxRequests {
            // Wait until oldest request is outside window
            if let oldest = timestamps.first {
                let sleepTime = interval - now.timeIntervalSince(oldest) + 0.1
                if sleepTime > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
                }
            }
        }
        
        timestamps.append(Date())
    }
}
