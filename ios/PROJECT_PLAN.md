# StackPulse Monitor - Project Plan

**Last Updated:** March 6, 2026  
**Status:** Feature-complete, needs testing & deployment

---

## ✅ Completed Features

- [x] iOS UI (SwiftUI) with tabs: Pulse, Stack, AI Chat, Settings
- [x] GitHub repository integration & metadata enrichment
- [x] Dependency health checking (OSV + endoflife.date APIs)
- [x] AI-powered analysis (GPT-4o)
- [x] SQLite local storage
- [x] Onboarding flow with GitHub OAuth
- [x] CI/CD GitHub Actions workflows

---

## 🎯 Remaining Tasks

### Phase 1: Testing (Priority)
- [ ] Implement unit tests for Models (Project, Dependency, TechType)
- [ ] Implement unit tests for ViewModels (AppViewModel)
- [ ] Implement unit tests for Services (GitHubAuthService, VersionCheckService, StorageService)
- [ ] Add 5+ meaningful test cases
- [ ] Verify CI workflow runs successfully

### Phase 2: Deployment
- [ ] Configure TestFlight (needs Apple Developer account)
- [ ] Add iOS distribution certificate to CI
- [ ] Set up App Store Connect credentials
- [ ] First TestFlight build

### Phase 3: Polish (Optional)
- [ ] Fix 1 TODO in GitHubAuthService (Phase 2 features)
- [ ] Fix 1 FIXME in MainTabView (onChange API)
- [ ] Add UI tests for critical paths

---

## 🚀 Deployment Checklist

| Item | Owner | Status |
|------|-------|--------|
| Unit tests | Dev | TODO |
| CI verification | Dev | TODO |
| Apple Developer account | Raphael | ACTION |
| TestFlight upload | CI | TODO |
| App Store submission | CI | TODO |

---

## 📚 Resources

- **Testing Plan:** `TESTING_PLAN.md`
- **GitHub:** https://github.com/aiagentmackenzie-lang/stackpulse-monitor
- **Local:** `~/Desktop/stackpulse-monitor/`

---

*Priority: Lower than CRUSHIT for now*
