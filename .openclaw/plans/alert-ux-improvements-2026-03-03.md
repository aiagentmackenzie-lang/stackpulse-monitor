# Plan: Alert UX Improvements

## Issue 1: Notifications Don't Auto-Dismiss

### Problem
- User views alert in app → Notification still shows in iOS Notification Center
- Badge clears on app open, but notification banners remain

### Solution: Mark Alerts as "Read"

**Approach A: Simple - Auto-dismiss when app opens**
- When app becomes active, cancel all pending notifications for viewed alerts
- Keep notifications for unviewed alerts

**Approach B: Smart - Track "read" status**
- Add `isRead` flag to TechAlert model
- When user opens Alerts tab, mark all visible as read
- Cancel notifications only for read alerts
- Keep notifications for unread alerts (even if dismissed in app)

**Recommended: Approach B** - More user-friendly, respects notification importance

### Implementation

1. **Add `isRead` to TechAlert model**
   ```swift
   struct TechAlert: Codable, Identifiable, Sendable {
       // existing fields...
       var isRead: Bool = false
       var readAt: Date?
   }
   ```

2. **Mark as read when viewed**
   - `AlertsView.onAppear` → mark all active alerts as read
   - Individual alert row tap → mark that one as read
   - Cancel notification for that specific alert

3. **Cancel notifications on read**
   ```swift
   UNUserNotificationCenter.current().removeDeliveredNotifications(
       withIdentifiers: [alert.id.uuidString]
   )
   ```

---

## Issue 2: "View Details" Navigation

### Problem
- "View Details" button on alert doesn't navigate anywhere
- User expects to see the dependency/project details

### Solution: Deep Link Navigation

**Target Views:**
1. **Project Alert** → Navigate to `ProjectDetailView`
   - Scroll to specific dependency if possible
   - Highlight the dependency
   
2. **Legacy Stack Alert** → Navigate to `StackView` or `TechnologyDetailView`

### Implementation

1. **Update AlertManager notification payload**
   ```swift
   content.userInfo = [
       "alertId": alert.id.uuidString,
       "techId": alert.techId.uuidString,
       "projectId": projectId?.uuidString,  // ADD THIS
       "type": alert.type.rawValue
   ]
   ```

2. **Handle notification tap in AppDelegate/App**
   - Parse `userInfo` for destination
   - Navigate to appropriate view

3. **In-app "View Details" navigation**
   - From AlertsView → Find project containing this dependency
   - Push ProjectDetailView
   - Optionally: scroll to/highlight the specific dependency

### Navigation Flow

```
User taps "View Details" on alert
        ↓
Find project containing techId
        ↓
If found:
    → Push ProjectDetailView
    → Highlight dependency section
    → Show version comparison
If not found (legacy):
    → Push TechnologyDetailView (if exists)
    → Or show alert details modal
```

---

## Priority

1. **Notification dismissal** - Medium priority (polish)
2. **View Details navigation** - High priority (core UX)

## Effort Estimate

- Notification dismissal: 30-45 min
- View Details navigation: 45-60 min

**Total: ~1.5-2 hours**
