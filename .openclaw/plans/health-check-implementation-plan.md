# Plan: Implement Registry API Calls for Health Check

## Overview
Complete implementation of `VersionCheckService.checkSingleVersion()` to enable health checks for My Stack and manual projects.

---

## Context

### Current State
- `VersionCheckService.checkSingleVersion()` is a stub returning `nil`
- GitHub repo imports work (fetch actual package.json)
- My Stack health check fails (calls stub)

### Root Cause
Health check for manual/My Stack projects never queries actual registries to find latest versions.

---

## Implementation Plan

---

## Chunk 1: Research Registry APIs (⏱️ 5 min)

**Task:** Determine API endpoints and request formats for major package registries.

**NPM Registry (for TechType.npm):**
- Endpoint: `https://registry.npmjs.org/{package-name}`
- Response: JSON with `{"dist-tags":{"latest":"x.y.z"}}`
- Example: `https://registry.npmjs.org/express` → `dist-tags.latest`

**PyPI (for TechType.pypi):**
- Endpoint: `https://pypi.org/pypi/{package-name}/json`
- Response: JSON with `{"info":{"version":"x.y.z"}}`
- Example: `https://pypi.org/pypi/requests/json` → `info.version`

**Crates.io (for Cargo/Rust):**
- Endpoint: `https://crates.io/api/v1/crates/{crate-name}`
- Response: JSON with `{"crate":{"newest_version":"x.y.z"}}`

**Packagist (for Composer/PHP):**
- Endpoint: `https://packagist.org/p/{vendor}/{package}.json`
- Response: JSON with `packages["version"]`

**RubyGems (for Ruby):**
- Endpoint: `https://rubygems.org/api/v1/gems/{gem-name}.json`
- Response: JSON with `{"version":"x.y.z"}`

**Maven Central (for Java):**
- Endpoint: `https://search.maven.org/solrsearch?q=g:{group}+AND+a:{artifact}&rows=1&wt=json`
- More complex, may need alternative

**Other/Special Cases:**
- Platform types (Node.js, Docker, etc.): May need different approach or API endpoint
- Language runtimes: Check official release APIs

---

## Chunk 2: Create Registry API Models (⏱️ 8 min)

**File:** `StackPulseMonitor/Services/RegistryAPIs.swift` (NEW)

**Content:**
```swift
import Foundation

// MARK: - Registry Response Models

struct NPMRegistryResponse: Codable {
    let distTags: DistTags
    
    struct DistTags: Codable {
        let latest: String
    }
    
    enum CodingKeys: String, CodingKey {
        case distTags = "dist-tags"
    }
}

struct PyPIResponse: Codable {
    let info: PyPIInfo
    
    struct PyPIInfo: Codable {
        let version: String
    }
}

struct CratesResponse: Codable {
    let crate: CrateInfo
    
    struct CrateInfo: Codable {
        let newestVersion: String
        
        enum CodingKeys: String, CodingKey {
            case newestVersion = "newest_version"
        }
    }
}

struct RubyGemsResponse: Codable {
    let version: String
}

// For registries not easily queryable
enum RegistryError: Error {
    case unsupportedPackageType
    case networkError
    case parsingError
    case notFound
    case rateLimited
}
```

---

## Chunk 3: Implement NPM Registry Call (⏱️ 10 min)

**File:** `StackPulseMonitor/Services/VersionCheckService.swift`

**Add to existing file:**
```swift
// MARK: - NPM Registry

func checkNPMVersion(package: String) async throws -> String? {
    let url = URL(string: "https://registry.npmjs.org/\(package.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? package)")!
    
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    print("🌐 Fetching NPM version for: \(package)")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        print("❌ NPM registry returned error: \(response)")
        throw RegistryError.notFound
    }
    
    let registryResponse = try JSONDecoder().decode(NPMRegistryResponse.self, from: data)
    let version = registryResponse.distTags.latest
    
    print("✅ NPM latest version: \(version)")
    return version
}

// Clean up package name for NPM
private func cleanNPMIdentifier(_ identifier: String) -> String {
    // Remove @scope/ prefix if present for API call
    // @types/node -> @types/node (keep scope)
    // @nestjs/core -> @nestjs/core (keep scope)
    // Remove version specifiers if accidentally included
    return identifier
        .replacingOccurrences(of: "^", with: "")
        .replacingOccurrences(of: "~", with: "")
        .components(separatedBy: "/")
        .first ?? identifier
}
```

---

## Chunk 4: Implement PyPI Registry Call (⏱️ 8 min)

**Add to VersionCheckService.swift:**
```swift
// MARK: - PyPI Registry (Python)

func checkPyPIVersion(package: String) async throws -> String? {
    // Clean package name (remove extras like "requests[socks]")
    let cleanName = package
        .components(separatedBy: "[")
        .first?
        .trimmingCharacters(in: .whitespaces) ?? package
    
    let encodedName = cleanName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleanName
    let url = URL(string: "https://pypi.org/pypi/\(encodedName)/json")!
    
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    print("🌐 Fetching PyPI version for: \(cleanName)")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 404 {
            print("⚠️ Package not found on PyPI: \(cleanName)")
            return nil
        }
        throw RegistryError.networkError
    }
    
    let registryResponse = try JSONDecoder().decode(PyPIResponse.self, from: data)
    let version = registryResponse.info.version
    
    print("✅ PyPI latest version: \(version)")
    return version
}
```

---

## Chunk 5: Implement Other Registries (⏱️ 10 min)

**Add to VersionCheckService.swift:**
```swift
// MARK: - Crates.io (Rust)

func checkCratesVersion(crate: String) async throws -> String? {
    let encodedName = crate.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? crate
    let url = URL(string: "https://crates.io/api/v1/crates/\(encodedName)")!
    
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("StackPulse-Monitor/1.0", forHTTPHeaderField: "User-Agent")
    
    print("🌐 Fetching Crates.io version for: \(crate)")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw RegistryError.notFound
    }
    
    let registryResponse = try JSONDecoder().decode(CratesResponse.self, from: data)
    return registryResponse.crate.newestVersion
}

// MARK: - RubyGems (Ruby)

func checkRubyGemsVersion(gem: String) async throws -> String? {
    let encodedName = gem.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? gem
    let url = URL(string: "https://rubygems.org/api/v1/gems/\(encodedName).json")!
    
    print("🌐 Fetching RubyGems version for: \(gem)")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw RegistryError.notFound
    }
    
    let registryResponse = try JSONDecoder().decode(RubyGemsResponse.self, from: data)
    return registryResponse.version
}

// MARK: - Platform/Runtime Versions

func checkPlatformVersion(platform: String) async throws -> String? {
    // Platform types (Node.js, Docker, Python runtime, etc.) need different handling
    // Could use:
    // - Node.js: https://nodejs.org/dist/index.json
    // - Docker: Docker Hub API (complex)
    // - Python: python-https://www.python.org/downloads/
    
    print("⚠️ Platform version checking not fully implemented for: \(platform)")
    return nil
}
```

---

## Chunk 6: Connect Everything (⏱️ 8 min)

**Replace stub `checkSingleVersion` with real implementation:**
```swift
func checkSingleVersion(
    identifier: String,
    type: TechType,
    currentVersion: String
) async throws -> String? {
    print("🔍 Checking version: \(identifier) (type: \(type))")
    
    switch type {
    case .npm:
        return try await checkNPMVersion(package: identifier)
        
    case .pypi:
        return try await checkPyPIVersion(package: identifier)
        
    case .cargo:
        return try await checkCratesVersion(crate: identifier)
        
    case .gem:
        return try await checkRubyGemsVersion(gem: identifier)
        
    case .platform:
        // Platform versions (Node.js, Docker, etc.) - simplified for now
        print("⚠️ Platform version checking is simplified")
        return nil
        
    default:
        print("⚠️ Unsupported package type: \(type)")
        return nil
    }
}
```

---

## Chunk 7: Handle Errors and Edge Cases (⏱️ 5 min)

**Add to checkVersions in AppViewModel:**

Update the error handling to gracefully handle cases where:
- Package not found in registry
- Network errors
- Unsupported package types

```swift
// In the loop checking each dependency:
do {
    if let latest = try await versionCheckService.checkSingleVersion(...) {
        // Update version
    }
} catch RegistryError.notFound {
    print("⚠️ Package not found: \(dep.name)")
    continue
} catch {
    print("❌ Error checking \(dep.name): \(error)")
    continue  // Continue with other dependencies
}
```

---

## Chunk 8: Add Info.plist Permissions (⏱️ 2 min)

**File:** `Info.plist`

Add to existing entries:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

*Note: For production app, use proper domain exceptions instead.*

---

## Chunk 9: Test Implementation (⏱️ 10 min)

**Test Cases:**
1. Add Express (npm) to My Stack
2. Tap Check for Updates
3. Verify console shows: "🌐 Fetching NPM version for: express"
4. Verify console shows: "✅ NPM latest version: x.x.x"
5. Verify latestVersion updates in project
6. Test error handling (non-existent package)
7. Test multiple dependency types if available

---

## Chunk 10: Cleanup and Documentation (⏱️ 3 min)

- Add comments explaining each registry API
- Document rate limits and caching considerations
- Remove diagnostic print statements (or keep for debugging)
- Commit with descriptive message

---

## Total Estimated Time: 69 minutes (11 chunks)
## Files Created: 1 (RegistryAPIs.swift)
## Files Modified: 2 (VersionCheckService.swift, Info.plist)
## Risk Level: MEDIUM (API calls, network handling)

## Testing Strategy
- Test with known packages first (express, requests)
- Verify error handling with fake package names
- Check network error scenarios (airplane mode)
- Validate version comparison logic still works

## Dependencies
- None external (uses URLSession)
- Relies on public registry APIs (no auth required)

## Future Improvements
- Add caching to avoid repeated API calls
- Handle rate limiting (implement exponential backoff)
- Add support for private registries
- Implement offline mode (use cached data)

---

## Acceptance Criteria
- [ ] My Stack health check fetches real versions from registries
- [ ] NPM packages resolve to registry.npmjs.org
- [ ] PyPI packages resolve to pypi.org
- [ ] Error handling works for non-existent packages
- [ ] GitHub repo imports continue working
- [ ] Health check triggers alerts based on real version data

---

## Branch
**polish** branch - commit when all chunks complete
**DO NOT MERGE TO MAIN** until thoroughly tested
