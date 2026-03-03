# Plan: Implement Registry API Health Check for My Stack
Created: 2026-03-03 14:30 BRT
Project: /Users/main/.openclaw/workspace/StackPulse-GitHub
Branch: polish
Priority: CRITICAL

## Problem Statement

**Root Cause Identified:** `VersionCheckService.checkSingleVersion()` is a stub returning `nil`. It never queries actual registries.

**Current Behavior:**
| Source | Health Check Works? | Why? |
|--------|---------------------|------|
| GitHub Repos | ✅ Yes | Fetches real package.json from GitHub API |
| My Stack (Manual/Presets) | ❌ No | Calls stub `checkSingleVersion()` → returns nil |

**Why GitHub Works:**
- `importRepository()` → fetches package.json from GitHub
- Parses versions from actual dependency files
- No registry API calls needed

**Why My Stack Fails:**
- `checkVersions(forProjectId:)` → loops through deps
- Calls `service.checkVersion(dep)` → which calls `checkSingleVersion()`
- Returns nil immediately
- No comparison possible
- No alerts generated

---

## Implementation: Registry API Calls

### Phase 1: Foundation (Chunks 1-3)

#### Chunk 1: Analyze Current Code (⏱️ 3 min)
**Spec:** Map current flow and identify exact injection points
**Files:** 
- `VersionCheckService.swift` (lines 1-100)

**Tasks:**
- [ ] Read current `VersionCheckService.swift`
- [ ] Document current `checkVersion()` method
- [ ] Identify where `checkSingleVersion()` is called
- [ ] Note existing `checkNPM()`, `checkPyPI()`, `checkCargo()` implementations

**Test:** 
```bash
grep -n "checkSingleVersion\|checkVersion\|checkNPM\|checkPyPI\|checkCargo" StackPulseMonitor/Services/VersionCheckService.swift
```

**Key Question:** Are `checkNPM()` etc. already implemented or also stubs?

---

#### Chunk 2: Verify Registry APIs (⏱️ 5 min)
**Spec:** Test registry endpoints return expected JSON
**Dependencies:** Chunk 1

**Test Commands:**
```bash
# NPM
curl -s "https://registry.npmjs.org/express/latest" | head -20

# PyPI
curl -s "https://pypi.org/pypi/requests/json" | head -20

# Crates.io
curl -s "https://crates.io/api/v1/crates/serde" | head -20
```

**Acceptance:**
- [ ] NPM returns JSON with `version` field
- [ ] PyPI returns JSON with `info.version` field
- [ ] Crates.io returns JSON with `crate.newest_version` field

---

#### Chunk 3: Design Registry Router (⏱️ 4 min)
**Spec:** Create type-based routing logic
**Dependencies:** Chunk 2

**Design:**
```swift
// In VersionCheckService.swift

func checkVersion(_ dependency: Dependency) async -> String? {
    switch dependency.type {
    case .npm:
        return await checkNPM(name: dependency.name)
    case .pypi:
        return await checkPyPI(name: dependency.name)
    case .cargo:
        return await checkCrates(name: dependency.name)
    case .gem:
        return await checkRubyGems(gem: dependency.name)
    case .platform, .language:
        // May need different approach
        return nil
    default:
        return nil
    }
}
```

**Registry Mapping:**
- `TechType.npm` → NPM Registry
- `TechType.pypi` → PyPI
- `TechType.cargo` → Crates.io
- `TechType.gem` → RubyGems
- `TechType.platform` → ? (Platform APIs)

---

### Phase 2: Implementation (Chunks 4-7)

#### Chunk 4: Implement full NPM Registry Call (⏱️ 5 min)
**Spec:** Replace stub with real NPM registry fetch
**Files:** `VersionCheckService.swift`
**Dependencies:** Chunk 3

**Code:**
```swift
private func checkNPM(name: String) async -> String? {
    let cleanName = name
        .replacingOccurrences(of: "\n", with: "")
        .adddingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
    
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
```

**Test:** Add Express (preset) → Tap "Check for Updates" → Should see:
```
🌐 Checking NPM version for: express
✅ Found: 4.21.2
```

---

#### Chunk 5: Implement full PyPI Registry Call (⏱️ 4 min)
**Spec:** Implement PyPI version fetch
**Files:** `VersionCheckService.swift`
**Dependencies:** Chunk 4

**Code:**
```swift
private func checkPyPI(name: String) async -> String? {
    let cleanName = name
        .components(separatedBy: "[")  // Remove extras
        .first?
        .trimmingCharacters(in: .whitespaces) ?? name
    
    let encodedName = cleanName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleanName
    let url = URL(string: "https://pypi.org/pypi/\(encodedName)/json")!
    
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
```

---

#### Chunk 6: Implement Crates.io Call (⏱️ 4 min)
**Spec:** Implement Rust crate version fetch
**Files:** `VersionCheckService.swift`
**Dependencies:** Chunk 5

**Code:**
```swift
private func checkCrates(name: String) async -> String? {
    let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
    let url = URL(string: "https://crates.io/api/v1/crates/\(encodedName)")!
    
    do {
        var request = URLRequest(url: url)
        request.setValue("StackPulse/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CratesResponse.self, from: data)
        return response.crate.newestVersion
    } catch {
        print("❌ Crates check failed for \(name): \(error)")
        return nil
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
```

---

#### Chunk 7: Implement RubyGems Call (⏱️ 3 min)
**Spec:** Implement Ruby gem version fetch
**Files:** `VersionCheckService.swift`
**Dependencies:** Chunk 6

**Code:**
```swift
private func checkRubyGems(gem: String) async -> String? {
    let encodedName = gem.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? gem
    let url = URL(string: "https://rubygems.org/api/v1/gems/\(encodedName).json")!
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RubyGemsResponse.self, from: data)
        return response.version
    } catch {
        print("❌ RubyGems check failed for \(gem): \(error)")
        return nil
    }
}

struct RubyGemsResponse: Codable {
    let version: String
}
```

---

### Phase 3: Integration (Chunks 8-9)

#### Chunk 8: Wire Router to checkVersion() (⏱️ 4 min)
**Spec:** Replace stub with working router
**Files:** `VersionCheckService.swift`
**Dependencies:** Chunk 7

**Before (stub):**
```swift
func checkVersion(_ dependency: Dependency) async -> String? {
    switch dependency.type {
    case .npm:
        return await checkNPM(name: dependency.name)
    case .pypi:
        return await checkPyPI(name: dependency.name)
    case .cargo:
        return await checkCargo(name: dependency.name)
    default:
        return nil
    }
}
```

**After (with error handling):**
```swift
func checkVersion(_ dependency: Dependency) async -> String? {
    print("🔍 Checking \(dependency.type): \(dependency.name)")
    
    switch dependency.type {
    case .npm:
        return await checkNPM(name: dependency.name)
    case .pypi:
        return await checkPyPI(name: dependency.name)
    case .cargo:
        return await checkCrates(name: dependency.name)
    case .gem:
        return await checkRubyGems(gem: dependency.name)
    default:
        print("⚠️ No registry for type: \(dependency.type)")
        return nil
    }
}
```

---

#### Chunk 9: Add Diagnostic Logging (⏱️ 3 min)
**Spec:** Add logging to trace health check flow
**Files:** 
- `VersionCheckService.swift`
- `AppViewModel.swift`

**Add to checkVersions() in AppViewModel:**
```swift
func checkVersions(forProjectId projectId: UUID) async {
    print("🔍 checkVersions START for project: \(projectId)")
    
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else {
        print("❌ Project not found: \(projectId)")
        return
    }
    
    print("📋 Project: \(projects[projectIndex].name)")
    print("📋 Dependencies: \(projects[projectIndex].dependencies.map { "\($0.name):\($0.currentVersion)" })")
    
    // ... rest of implementation
}
```

---

### Phase 4: Testing & Validation (Chunks 10-11)

#### Chunk 10: Test with Presets (⏱️ 5 min)
**Spec:** Verify My Stack health check works end-to-end
**Dependencies:** Chunk 9

**Test Steps:**
1. Fresh app install
2. Complete onboarding
3. Select presets: Express, React, Node.js
4. Set specific versions: Express 4.17.3 (older than latest)
5. Complete onboarding → Creates "My Stack" project
6. Go to Projects → My Stack
7. Tap "Check for Updates"

**Expected Console Output:**
```
🔍 checkVersions START for project: [uuid]
📋 Project: My Stack
📋 Dependencies: ["express:4.17.3", "react:18.3.0", "node:20.12.0"]
🔍 Checking npm: express
🌐 Fetching NPM version for: express
✅ NPM latest version: 4.21.2
📊 Comparing: current=4.17.3, latest=4.21.2
⚠️ Outdated detected
🚨 Alert created: Express major update available
```

---

#### Chunk 11: Error Handling & Edge Cases (⏱️ 4 min)
**Spec:** Handle failures gracefully
**Dependencies:** Chunk 10

**Edge Cases:**
- [ ] Network failure → Continue with other deps
- [ ] Package not found → Log warning, continue
- [ ] Rate limited → Backoff and retry
- [ ] Empty currentVersion → Skip check
- [ ] Version already latest → No alert

**Code Pattern:**
```swift
for dep in deps {
    do {
        if let latest = try await service.checkVersion(dep) {
            // Compare and update
        }
    } catch {
        print("❌ Error checking \(dep.name): \(error)")
        continue // Skip but don't fail entire check
    }
}
```

---

## Registry API Reference

### NPM (Node.js)
```
GET https://registry.npmjs.org/{package}/latest
Response: {"version": "x.y.z"}
Example: express → 4.21.2
```

### PyPI (Python)
```
GET https://pypi.org/pypi/{package}/json
Response: {"info": {"version": "x.y.z"}}
Example: requests → 2.32.3
```

### Crates.io (Rust)
```
GET https://crates.io/api/v1/crates/{crate}
Response: {"crate": {"newest_version": "x.y.z"}}
Example: serde → 1.0.218
Headers: User-Agent required
```

### RubyGems (Ruby)
```
GET https://rubygems.org/api/v1/gems/{gem}.json
Response: {"version": "x.y.z"}
Example: rails → 7.1.3
```

---

## Files to Modify

| File | Change |
|------|--------|
| `VersionCheckService.swift` | Replace stubs with real registry calls |
| `AppViewModel.swift` | Add diagnostic logging |

## Files Created

None — all changes to existing files.

---

## Total Estimated Time: 40 minutes
## Chunk Count: 11
## Risk Level: MEDIUM

## Rollback Strategy
```bash
git checkout polish
git reset --hard HEAD~1  # If needed
```

## Success Criteria
- [ ] My Stack "Check for Updates" fetches real versions
- [ ] Alerts generated when versions differ
- [ ] No regression for GitHub repo imports
- [ ] Graceful handling of network errors

## Context for Next Session

**The Core Issue:** `checkSingleVersion()` stub in `VersionCheckService.swift` returns nil, never calling registries. This is why My Stack health check fails.

**The Fix:** Implement actual registry API calls in `checkVersion()` method based on `TechType`.

**Key Discovery:** Existing `checkNPM()`, `checkPyPI()`, `checkCargo()` methods may already be there or may be stubs too. Need to verify first.

**Test Approach:** Use Express preset with old version → should detect update.
