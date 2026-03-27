# StackPulse Testing & Deployment Plan

## 📋 Overview

This document outlines the complete testing strategy, deployment pipeline, and maintenance procedures for StackPulse Monitor iOS app.

---

## 🧪 Testing Strategy

### 1. Unit Tests (`StackPulseMonitorTests/`)

**Current Status:** Template only - needs implementation

**Priority Test Areas:**
- [ ] **Model Tests** - Project, Dependency, TechType, TechCategory
- [ ] **ViewModel Tests** - AppViewModel business logic
- [ ] **Service Tests** - GitHubAuthService, VersionCheckService, StorageService
- [ ] **Utility Tests** - Theme, Extensions, TechnologyKnowledge

**Example Test Structure:**
```swift
// StackPulseMonitorTests/Models/ProjectTests.swift
import Testing
@testable import StackPulseMonitor

struct ProjectTests {
    @Test func healthScoreCalculatesCorrectly() {
        let project = Project(name: "Test", source: .manual, dependencies: [
            Dependency(name: "react", type: .npm, category: .frontend, 
                      currentVersion: "18.2.0", latestVersion: "18.2.0", isOutdated: false),
            Dependency(name: "lodash", type: .npm, category: .backend,
                      currentVersion: "4.17.20", latestVersion: "4.17.21", isOutdated: true)
        ])
        #expect(project.healthScore == 50)
    }
}
```

### 2. UI Tests (`StackPulseMonitorUITests/`)

**Current Status:** Basic template - needs implementation

**Priority Test Scenarios:**
- [ ] **Navigation Tests** - Tab switching, navigation stack
- [ ] **Project List** - Add, delete, expand projects
- [ ] **Project Detail** - Health score display, dependency list
- [ ] **Onboarding Flow** - First launch, GitHub auth
- [ ] **Settings** - Alert preferences persistence
- [ ] **AI Chat** - Message sending, response display

### 3. Integration Tests

**Areas to Cover:**
- [ ] GitHub API authentication flow
- [ ] Local storage persistence (SQLite)
- [ ] Version check service with mock API
- [ ] AI service integration

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

#### 1. CI Workflow (`.github/workflows/ci.yml`)

| Job | Status | Description |
|-----|--------|-------------|
| `test` | ✅ Created | Runs unit tests on iOS Simulator |
| `build` | ✅ Created | Builds for iOS Device + Simulator |
| `lint` | ✅ Created | SwiftLint code quality |

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main`

#### 2. Deploy Workflow (`.github/workflows/deploy.yml`)

| Job | Status | Description |
|-----|--------|-------------|
| `build-ipa` | ✅ Created | Builds IPA for distribution |
| `testflight` | ✅ Created | Uploads to TestFlight |
| `github-release` | ✅ Created | Creates GitHub release with IPA |

**Triggers:**
- New tag `v*` (e.g., `v1.0.0`)
- Manual dispatch

---

## 🚀 Deployment Process

### Manual Deployment (Current)

1. **Build:**
   ```bash
   cd ~/Desktop/stackpulse-monitor
   xcodebuild -project StackPulseMonitor.xcodeproj \
     -scheme StackPulseMonitor \
     -configuration Debug \
     -destination 'generic/platform=iOS' build
   ```

2. **Install on Device:**
   ```bash
   xcrun devicectl device install app \
     --device "iPhone" \
     ~/Library/Developer/Xcode/DerivedData/StackPulseMonitor-*/Build/Products/Debug-iphoneos/StackPulseMonitor.app
   ```

3. **Launch:**
   ```bash
   xcrun devicectl device process launch \
     --device "iPhone" \
     app.rork.stackpulse-monitor
   ```

### Automated Deployment (Future)

1. Push version tag: `git tag v1.0.0 && git push origin v1.0.0`
2. CI builds IPA automatically
3. Deploys to TestFlight
4. Creates GitHub release

---

## 🔧 Maintenance Plan

### 1. Weekly Maintenance

| Task | Frequency | Status |
|------|-----------|--------|
| Run full test suite | Weekly | TODO |
| Review test coverage | Weekly | TODO |
| Update dependencies | Weekly | TODO |
| Clean DerivedData | Weekly | Manual |

### 2. Monthly Maintenance

| Task | Frequency | Status |
|------|-----------|--------|
| Xcode update | Monthly | Manual |
| SwiftLint rules review | Monthly | TODO |
| Performance profiling | Monthly | TODO |
| Security audit | Monthly | Manual |

### 3. Release Maintenance

| Task | Frequency | Status |
|------|-----------|--------|
| Version bump | Per release | TODO |
| Changelog update | Per release | TODO |
| TestFlight beta | Per release | TODO |
| App Store submission | Per release | Manual |

---

## 📊 Test Coverage Goals

| Category | Target | Current |
|----------|--------|---------|
| Models | 90% | 0% |
| ViewModels | 80% | 0% |
| Services | 70% | 0% |
| UI | 50% | 0% |
| **Overall** | **70%** | **0%** |

---

## 🔨 Running Tests

### Local Testing

```bash
# Run all tests
xcodebuild test \
  -project StackPulseMonitor.xcodeproj \
  -scheme StackPulseMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run with coverage
xcodebuild test \
  -project StackPulseMonitor.xcodeproj \
  -scheme StackPulseMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES
```

### Using Testing Skill

```bash
# Check test environment
~/.openclaw/workspace/skills/testing/scripts/test-check.sh

# Run tests (auto-detect)
test-run --path ~/Desktop/stackpulse-monitor --type swift
```

---

## 📝 Action Items

### Immediate (This Week)
- [ ] Implement basic unit tests for Models
- [ ] Add 5+ meaningful test cases
- [ ] Verify CI workflow runs successfully

### Short-term (This Month)
- [ ] Achieve 50% test coverage
- [ ] Implement UI tests for critical paths
- [ ] Set up automatic coverage reporting

### Long-term (This Quarter)
- [ ] Achieve 70% test coverage
- [ ] Configure TestFlight deployment
- [ ] Implement automated release process

---

## 🔐 Secrets Required for CI/CD

| Secret | Purpose | Status |
|--------|---------|--------|
| `CODECOV_TOKEN` | Coverage reporting | Needed |
| `CERTIFICATE` | iOS distribution | Needed |
| `CERTIFICATE_KEY_PASSWORD` | Certificate password | Needed |
| `PROVISIONING_PROFILE` | App provisioning | Needed |
| `TEAM_ID` | Apple Team ID | Needed |
| `APPLE_CONNECT_USERNAME` | App Store Connect | Needed |
| `APPLE_CONNECT_PASSWORD` | App Store Connect | Needed |
| `APPLE_TEAM_ID` | App Store Team | Needed |

---

*Last Updated: March 4, 2026*
