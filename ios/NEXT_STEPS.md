# StackPulse Monitor - Next Steps

**Last Updated:** March 9, 2026, 4:08 PM

---

## ✅ COMPLETED

### Tests (March 9)
- [x] All 60+ tests passing
- [x] Fixed TechnologyTests (explicit status parameter)
- [x] Fixed healthScore to use projects (new model) not legacy stackItems
- [x] Fixed AppViewModelTests expectations

### Git
- [x] Pushed fixes: "fix: Resolve test failures and healthScore calculation"

---

## 📋 TO DO (Priority Order)

### 1. CI Workflow
- [ ] Simplify `.github/workflows/ci.yml`
- [ ] Remove Codecov upload (no token)
- [ ] Remove SwiftLint (not configured)
- [ ] Keep: test → build jobs only

### 2. Apple Developer Account
- [ ] Get Apple Developer Program ($99/year)
- [ ] URL: https://developer.apple.com/enroll/
- [ ] Set up App Store Connect
- [ ] Create certificates + provisioning profiles

### 3. TestFlight Deployment
- [ ] Set up ios-deploy skill
- [ ] Configure CI for TestFlight upload
- [ ] First TestFlight build

---

## 📁 Key Files

- `StackPulseMonitor/ViewModels/AppViewModel.swift` — Fixed healthScore
- `StackPulseMonitorTests/ServiceTests.swift` — Fixed TechnologyTests
- `StackPulseMonitorTests/AppViewModelTests.swift` — Fixed expectations

---

## 🔗 Links

- Repo: https://github.com/aiagentmackenzie-lang/stackpulse-monitor
- CI Workflow: `.github/workflows/ci.yml`

---

**Status:** Tests passing, ready for CI fix → Apple Dev account → TestFlight
