# StackPulse Monitor - Next Steps

**Last Updated:** March 9, 2026, 12:31 PM

---

## Current Status

### Tests
- **Passed:** ~46/51 (~90%)
- **Failed:** 5 tests

### Failed Tests
1. `TechnologyTests/technologyStatusUpdate()`
2. `TechnologyTests/technologyStatusOK()`
3. `AppViewModelTests/healthScore0Percent()`
4. `AppViewModelTests/removeProject()`
5. `AppViewModelTests/healthScore50Percent()`

### CI Workflow
- Current `.github/workflows/ci.yml` is broken (Codecov + SwiftLint not configured)
- Needs simplification to just test + build

---

## To Do List (Priority Order)

### 1. Fix Failing Tests (Quick)
- [ ] Investigate and fix the 5 failing tests
- [ ] Re-run tests to confirm all pass

### 2. CI Workflow
- [ ] Update `.github/workflows/ci.yml` to simplified version
- [ ] Remove Codecov upload (no token)
- [ ] Remove SwiftLint (not configured)
- [ ] Keep: test → build jobs only

### 3. Apple Developer Account
- [ ] Get Apple Developer Program ($99/year)
- [ ] Set up App Store Connect
- [ ] Create certificates + provisioning profiles

### 4. TestFlight Deployment
- [ ] Set up ios-deploy skill
- [ ] Configure CI for TestFlight upload
- [ ] First TestFlight build

---

## Notes
- Skill `testing` available for local test runs
- Skill `cicd` has better iOS workflow template
- Skill `ios-deploy` for TestFlight uploads

---

**Shelved:** After lunch - continue from here
