# Plan: Alert Notification UI Implementation
Created: 2026-03-03 10:52 AM
Project: /Users/main/.openclaw/workspace/StackPulse-GitHub
Branch: feature/alerts-enhancement

## Overview
Build complete alert notification UI (Settings + Onboarding) for StackPulse Monitor alert system.

## Context
- AlertManager.swift exists (backend ready)
- UserAlertPrefs.swift exists (data model ready)
- StorageService updated (persistence ready)
- AppViewModel integrated (hooked up)
- MISSING: User-facing UI for preferences
- MISSING: Permission onboarding flow

---

## Chunk 1: Update Info.plist for Notification Permissions (⏱️ 2 min)
**Spec:** Add NSCameraUsageDescription and all notification-related plist entries needed for iOS permission dialogs
- Add NSUserNotificationUsageDescription key
- Add UIBackgroundModes with "fetch" and "remote-notification" if background refresh desired

**Files:** `Info.plist`

**Test:** Open plist in Xcode, verify keys present

---

## Chunk 2: Create AlertPreferencesSection View Component (⏱️ 4 min)
**Spec:** Reusable SwiftUI component for toggling alert preferences
- Master toggle: "Enable Alert Notifications"
- Sub-toggles (disabled if master off):
  - "Critical Vulnerabilities" (default ON)
  - "Version Updates" (default ON)
  - "End-of-Life Warnings" (default OFF)
  - "Breaking Changes" (default ON)
- Quiet Hours section:
  - Toggle "Enable Quiet Hours"
  - Time pickers for start/end
  
**Files:** 
- `StackPulseMonitor/Views/Settings/AlertPreferencesSection.swift` (new)

**Test:** Preview renders correctly, toggles animate, time pickers functional

**Dependencies:** Requires Chunk 1 complete

---

## Chunk 3: Create Project-specific Alert Settings View (⏱️ 5 min)
**Spec:** Allow per-project alert customization
- Navigate from Project Detail → Alert Settings
- Show same toggles as global but scoped to project
- "Use Global Settings" toggle (default ON)
- When OFF: show custom project alert preferences

**Files:**
- `StackPulseMonitor/Views/Settings/ProjectAlertSettingsView.swift` (new)

**Test:** Navigate from project, toggle "Use Global" shows/hides custom controls

**Dependencies:** Chunk 2 complete

---

## Chunk 4: Integrate AlertPreferences into SettingsView (⏱️ 3 min)
**Spec:** Add AlertPreferencesSection to main Settings tab
- Insert after "Account" section or at end
- Section header: "Notifications"
- Uses @State and binds to alertManager.prefs

**Files:**
- `StackPulseMonitor/Views/SettingsView.swift` (modify)

**Test:** Open Settings → see Notifications section → toggles work

**Dependencies:** Chunk 2 complete

---

## Chunk 5: Add Notification Permission to Onboarding (⏱️ 5 min)
**Spec:** Add new onboarding step for notification permission
- New view: OnboardingNotificationsView
- Explains: "Get notified when your dependencies have vulnerabilities"
- Two buttons:
  - "Enable Notifications" → requests permission → moves to next step
  - "Maybe Later" → skips → moves to next step
- Integrate into OnboardingView flow (step 4 or 5)
- Calls viewModel.checkNotificationPermissions() when enabled

**Files:**
- `StackPulseMonitor/Views/Onboarding/OnboardingNotificationsView.swift` (new)
- `StackPulseMonitor/Views/OnboardingView.swift` (modify flow)

**Test:** Fresh install → onboarding → see notification step → both buttons work → permission requested

**Dependencies:** Chunk 1 complete

---

## Chunk 6: Add Project Alert Settings Navigation (⏱️ 3 min)
**Spec:** Add "Alert Settings" button to ProjectDetailView
- Button in toolbar or in action sheet
- Opens ProjectAlertSettingsView as sheet
- Passes project and viewModel as bindings

**Files:**
- `StackPulseMonitor/Views/ProjectDetailView.swift` (modify)

**Test:** Open project → tap Alert Settings → sheet opens → changes persist

**Dependencies:** Chunk 3 complete

---

## Chunk 7: Create App Icon Badge Support (⏱️ 3 min)
**Spec:** Show badge on app icon when alerts exist
- Set badge count = activeAlerts.count
- Clear badge when user opens app
- Use AlertManager.clearBadge()

**Files:**
- `StackPulseMonitor/StackPulseMonitorApp.swift` (modify scenePhase)
- `StackPulseMonitor/ViewModels/AppViewModel.swift` (modify to set badge)

**Test:** Have alerts → see badge count on home screen → open app → badge clears

**Dependencies:** Chunk 5 complete

---

## Chunk 8: Test End-to-End Flow (⏱️ 5 min)
**Spec:** Verify complete user journey
1. Fresh install → onboarding shows notification permission
2. Enable notifications → permission granted
3. Settings → Notifications section visible
4. Toggle settings → save to UserDefaults
5. Add project → set project-specific alert preferences
6. Run sync → alerts created → local notification fires

**Files:** None (test run)

**Test:** Deploy to device, walk through entire flow, verify notifications fire

**Dependencies:** All chunks complete

---

## Chunk 9: Polish and Documentation (⏱️ 3 min)
**Spec:** Clean code, add comments, update README
- Add descriptive comments to new views
- Update README with alert settings feature
- Verify no debug print statements
- Check dark mode compatibility

**Files:**
- README.md (modify)
- All new files (add comments)

**Test:** Read code, understand purpose from comments alone

---

## Total Estimated Time: 33 minutes
## Files Created: 5 new
## Files Modified: 5 existing
## Risk Level: LOW (isolated UI additions)
## Rollback Strategy: Delete branch, start fresh
