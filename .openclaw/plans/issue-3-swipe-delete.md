# Plan: Swipe to Delete Alerts
Branch: polish
Priority: MEDIUM

## Root Cause
Alerts can only be "dismissed" (hidden) via context menu, no swipe gesture.

## Changes

### Chunk 1: Add Swipe Action to Alert Row (⏱️ 5 min)
**File:** Views/AlertsView.swift (~alertCard function)

Add `.swipeActions`:
- Leading: "Mark Read" button (optional)
- Trailing: "Delete" button (red)
- Call `viewModel.deleteAlert()`

### Chunk 2: Add Delete Method to ViewModel (⏱️ 3 min)
**File:** ViewModels/AppViewModel.swift

Add:
```swift
func deleteAlert(_ alertId: UUID) {
    alerts.removeAll { $0.id == alertId }
    storage.saveAlerts(alerts)
    // Cancel notification if exists
    alertManager.cancelNotification(for: alertId)
}
```

### Chunk 3: Add Haptic Feedback (⏱️ 2 min)
**File:** Views/AlertsView.swift

Add haptic feedback on delete:
- `.sensoryFeedback(.delete, trigger: isDeleted)`

### Chunk 4: Update Storage (⏱️ 2 min)
**File:** Services/StorageService.swift

Ensure saveAlerts handles deleted items correctly (already does).

### Chunk 5: Test Delete Flow (⏱️ 3 min)
**Test:** 
- Swipe left on alert
- Tap delete
- Alert disappears immediately
- Notification cancels
- No crash

## Total: 15 minutes
## Test: Alerts list → swipe → delete → gone
