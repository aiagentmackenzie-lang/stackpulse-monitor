# Plan: Notification Dismissal + View Details Navigation
Created: 2026-03-03 11:55 AM

---

## FEATURE 1: Notification Dismissal (Mark Alerts as Read)

### Chunk 1.1: Update TechAlert Model (⏱️ 3 min)
**Spec:** Add `isRead` and `readAt` fields to TechAlert
- Add `isRead: Bool` with default false
- Add `readAt: Date?` optional
- Ensure Codable compliance

**Files:** `StackPulseMonitor/Models/TechAlert.swift`

**Test:** Model compiles, JSON encoding/decoding works

---

### Chunk 1.2: Add Alert Reading Methods (⏱️ 4 min)
**Spec:** Methods to mark alerts as read in AppViewModel
- `markAlertAsRead(alertId:)` - single alert
- `markAllAlertsAsRead()` - all active alerts
- Cancel notification when marked read

**Files:** `StackPulseMonitor/ViewModels/AppViewModel.swift`

**Test:** Can mark individual and all alerts as read

---

### Chunk 1.3: Mark on View (⏱️ 3 min)
**Spec:** Auto-mark as read when user views
- `AlertsView.onAppear` → call `markAllAlertsAsRead()`
- Individual row tap → call `markAlertAsRead()`

**Files:** `StackPulseMonitor/Views/AlertsView.swift`

**Test:** Viewing alerts marks them read, clears notifications

---

### Chunk 1.4: Update AlertManager (⏱️ 2 min)
**Spec:** Cancel delivered notifications for read alerts
- Add helper to cancel specific notification
- Call when marking alert as read

**Files:** `StackPulseMonitor/Services/AlertManager.swift`

**Test:** Notification disappears from Notification Center

---

## FEATURE 2: View Details Navigation

### Chunk 2.1: Update Notification Payload (⏱️ 2 min)
**Spec:** Add projectId to notification userInfo
- Include `projectId` when scheduling notification
- Helps with routing from notification tap

**Files:** `StackPulseMonitor/Services/AlertManager.swift`

**Test:** Payload contains all needed IDs

---

### Chunk 2.2: Add Navigation Helper (⏱️ 5 min)
**Spec:** Find project for given alert
- `findProject(forTechId:)` method in AppViewModel
- Returns Project? if found
- Handles both project dependencies and legacy stack

**Files:** `StackPulseMonitor/ViewModels/AppViewModel.swift`

**Test:** Can locate project from techId/dependencyId

---

### Chunk 2.3: Update Alert Row (⏱️ 4 min)
**Spec:** Make "View Details" button navigate
- Add navigation binding
- Route to ProjectDetailView if project found
- Show detail modal if legacy

**Files:** `StackPulseMonitor/Views/AlertsView.swift`

**Test:** Tap View Details → navigates to project

---

### Chunk 2.4: Add Project Navigation (⏱️ 4 min)
**Spec:** Navigate from Alerts to ProjectDetail
- Add NavigationLink or sheet presentation
- Pass project and viewModel
- Mark alert as read on navigation

**Files:** `StackPulseMonitor/Views/AlertsView.swift`

**Test:** Full flow: Alert → View Details → Project Detail

---

### Chunk 2.5: Handle Notification Tap (⏱️ 5 min)
**Spec:** Deep link from notification tap
- Parse notification userInfo
- Navigate to appropriate view
- Handle both foreground and background taps

**Files:** `StackPulseMonitor/StackPulseMonitorApp.swift`

**Test:** Tap notification → opens app to correct project

---

## Total Estimated Time: 32 minutes (9 chunks)
## Commits: 2 (one per feature)
## Risk Level: LOW (additive changes)
