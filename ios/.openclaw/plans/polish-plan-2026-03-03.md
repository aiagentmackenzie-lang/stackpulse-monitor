# StackPulse Polish Plan - March 3, 2026

## Overview
Address 3 UX improvements identified during main branch testing.

---

## ISSUE 1: Onboarding Missing Version Input

### Problem
When manually adding a dependency during onboarding, user cannot specify current version. This causes health check to fail/skip because it has no baseline version to compare against.

### Root Cause
- `ManualEntryView` (onboarding step) only asks for dependency name
- `Dependency` created with empty/null `currentVersion`
- Health check requires `currentVersion` to determine if update exists

### Solution
**Modify ManualEntryView to:**
1. Add version input field alongside name
2. Make version optional but encouraged
3. Show validation: "Health check works better with version specified"
4. Pre-populate version if known (e.g., from package.json detection)

### Files to Modify
- `StackPulseMonitor/Views/Onboarding/ManualEntryView.swift`
- `StackPulseMonitor/ViewModels/AppViewModel.swift` (validate version exists)

### Acceptance Criteria
- [ ] User can enter version when adding manual dependency
- [ ] Optional: Pre-fill from common patterns (package.json, requirements.txt)
- [ ] Health check runs successfully with manual entries
- [ ] Visual indicator if version is missing

---

## ISSUE 2: Enhanced GitHub Context for AI

### Problem
AI chat doesn't understand project context - it only sees dependencies, not what the project actually does.

### Root Cause
- `GitHubImporter` only fetches dependency lists
- No README, description, or project metadata fetched
- AI has no context for meaningful conversations

### Solution
**Enhance GitHub sync to:**
1. Fetch repository metadata (description, topics, language)
2. Fetch and truncate README (first 2000 chars)
3. Store in `Project` model as `aiContext` field
4. Include context in AI chat prompts

### Files to Modify
- `StackPulseMonitor/Models/Project.swift` - Add aiContext field
- `StackPulseMonitor/Services/GitHubImporter.swift` - Fetch README/description
- `StackPulseMonitor/Services/StorageService.swift` - Save/load aiContext
- `StackPulseMonitor/Views/AI/` - Include context in prompts

### API Calls Needed
```
GET /repos/{owner}/{repo} → description, topics, language
GET /repos/{owner}/{repo}/readme → content (base64 decode)
```

### Acceptance Criteria
- [ ] Project stores README excerpt and description
- [ ] AI chat references project purpose when discussing dependencies
- [ ] Context loads automatically with GitHub sync
- [ ] Falls back gracefully if no README

---

## ISSUE 3: Swipe to Delete Alerts

### Problem
Alerts remain visible indefinitely after reading. Users want to dismiss individual alerts.

### Current Behavior
- Alerts can be "dismissed" but stay in data model (isDismissed flag)
- Only way to remove is "Clear All" button
- No granular control

### Solution
**Add swipe-to-delete:**
1. In `AlertsView`, add `.swipeActions` to each alert card
2. "Delete" action permanently removes alert
3. "Dismiss" action keeps current behavior (marks dismissed)
4. Add empty state for deleted alerts

### Files to Modify
- `StackPulseMonitor/Views/AlertsView.swift` - Add swipe delete
- `StackPulseMonitor/ViewModels/AppViewModel.swift` - Add deleteAlert method

### Acceptance Criteria
- [ ] Swipe left reveals "Delete" action
- [ ] Delete permanently removes alert from list
- [ ] Visual feedback (animation) on delete
- [ ] Works with existing dismiss/snooze actions

---

## Implementation Order

### Phase 1: Critical (Issue 1)
**Onboarding version fix** - Blocks core functionality (health check)
Estimated: 20 minutes

### Phase 2: UX Enhancement (Issue 3)
**Swipe to delete alerts** - Improves daily usage
Estimated: 15 minutes

### Phase 3: AI Enhancement (Issue 2)
**GitHub context for AI** - Complex, requires API calls + data model
Estimated: 45 minutes

---

## Risk Assessment

| Issue | Risk | Mitigation |
|-------|------|------------|
| 1. Onboarding | Low | Add optional field, existing validation handles empty |
| 2. GitHub Context | Medium | Add new field, migration handles nil gracefully |
| 3. Swipe Delete | Low | SwiftUI native swipeActions, well-tested pattern |

---

## Testing Checklist

- [ ] Fresh install - onboarding with version
- [ ] GitHub import - pulls README context
- [ ] AI chat - references project context
- [ ] Alerts - swipe delete works
- [ ] Existing features - no regressions
