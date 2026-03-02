# Plan: AI Placement Across App (Options 1, 2, 3)

**Created:** 2026-03-02 15:18  
**Goal:** Make AI accessible from nav bar, pulse contextual, and project cards  
**Estimated Time:** 35 minutes  
**Max Chunk Time:** 10 minutes  

---

## Overview

| Option | Placement | User Sees | Value |
|--------|-----------|-----------|-------|
| **1** | Nav Bar (top right) | [✨ AI] button always visible | One-tap access anywhere |
| **2** | Pulse Contextual | [✨ Get AI Insights on All] banner | Executive view of all projects |
| **3** | Project Cards | [✨ Analyze] inline per card | Zero-friction per-project |

---

## Chunk 1: Nav Bar AI Button (Option 1) ⏱️ 8 min

**Spec:** Add [✨ AI] button to MainTabView toolbar that opens smart action menu

**File:** `Views/MainTabView.swift`

**Behavior:**
- Button visible on ALL tabs
- Taps → Sheet with "What's on your mind?"
  - "Analyze all my projects" → Option 2 flow
  - "Analyze specific project" → Project picker
  - "View last AI report" → If exists

**UI:**
```
MainTabView                                    
┌─────────────────────────────────────┐
│  Pulse                    [✨ AI] │  ← Top right button
├─────────────────────────────────────┤
│                                     │
```

**Sheet UI:**
```
┌─────────────────────────────────────┐
│  ✨ AI Assistant                    │
├─────────────────────────────────────┤
│                                     │
│  What would you like to analyze?    │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  📊 All My Projects        │   │
│  │     3 projects, 5 outdated │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  📁 Specific Project       │   │
│  │     Select to analyze      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  📋 View Last Report       │   │
│  │     MyRepo - Generated     │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Test:** Button visible on all tabs, sheet opens, navigates correctly  
**Status:** ⬜

---

## Chunk 2: Pulse Contextual AI (Option 2) ⏱️ 10 min

**Spec:** Add "✨ Get AI Insights on All" banner at top of Pulse tab

**File:** `Views/PulseView.swift`

**Behavior:**
- Shows only if there are outdated deps across projects
- One button analyzes ALL projects with issues
- Returns consolidated report:
  - "You have 12 outdated deps across 3 projects"
  - "2 critical security, 8 safe, 2 review needed"
  - Cross-project action plan

**UI:**
```
┌─────────────────────────────────────┐
│  Pulse                             │
├─────────────────────────────────────┤
│                                     │
│  ✨ AI Insights Banner             │  ← NEW
│  Your stack needs attention         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  🔮 Analyze All Projects   │   │
│  │  12 updates across 3 repos  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ────────────────────────────       │
│                                     │
│  📁 MyRepo                 [67%]   │
│  ...                               │
│                                     │
└─────────────────────────────────────┘
```

**New Model:** `MultiProjectAIReport`
```swift
struct MultiProjectAIReport: Codable {
    let generatedAt: Date
    let summary: String  // "12 updates across 3 projects"
    let totalOutdated: Int
    let criticalCount: Int
    let safeCount: Int
    let reviewCount: Int
    let crossProjectPlan: [String]  // Prioritized across all projects
    let projects: [ProjectAIReport]  // Individual reports
}
```

**Test:** Banner shows when outdated deps exist, generates multi-project report  
**Status:** ⬜

---

## Chunk 3: Project Cards AI (Option 3) ⏱️ 8 min

**Spec:** Add [✨ Analyze] button inline on each PulseProjectCard

**File:** `Views/Components/PulseProjectCard.swift`

**Behavior:**
- Shows on every project card (if project has outdated deps)
- Tap → instant AI analysis without opening detail view
- Sheet pops up with full AI report (reuse existing sheet)

**UI:**
```
┌─────────────────────────────────────┐
│                                     │
│  📁 MyRepo                 [67%]   │
│  12 deps | 3 outdated ⚠️            │
│                                     │
│  ┌──────────┬────────────────┐    │
│  │ View →   │  ✨ Analyze     │    │  ← Two buttons
│  └──────────┴────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**Layout:**
```swift
HStack {
    Spacer()
    
    Button("View") { onTap() }  // Existing
        .buttonStyle(.bordered)
    
    Button("✨ Analyze") { onAnalyze() }  // NEW
        .buttonStyle(.borderedProminent)
        .tint(.purple)
}
```

**Test:** Button appears on cards with outdated deps, opens AI report sheet  
**Status:** ⬜

---

## Chunk 4: Wire Up Navigation (5 min)

**Spec:** Ensure all AI buttons navigate to correct destinations

**Files:**
- `MainTabView.swift` → Sheet → Option 2 or Project Picker
- `PulseView.swift` → Sheet → MultiProjectReportSheet
- `PulseProjectCard.swift` → Sheet → AIReportSheet

**Routing Logic:**
```swift
// Nav bar button
if selectedTab == .pulse {
    showMultiProjectAIAnalysis()
} else {
    showAISheetMenu()
}

// Project card
onAnalyze: { showAIReportSheet(for: project) }

// Pulse contextual
onAnalyzeAll: { showMultiProjectAIReport() }
```

**Status:** ⬜

---

## Chunk 5: Build & Test Integration (4 min)

**Spec:** Verify all three placements work without breaking existing flow

**Test Matrix:**
| Flow | Expected | Status |
|------|----------|--------|
| Tap nav bar [✨ AI] on Pulse | Show multi-project option | ⬜ |
| Tap nav bar [✨ AI] on Projects | Show project picker | ⬜ |
| Tap [✨ Analyze] on project card | Show AI report sheet | ⬜ |
| Tap [🔮 Analyze All] in Pulse | Generate multi-project report | ⬜ |
| Existing detail view AI button | Still works | ⬜ |

**Commit:** "feat: place AI in nav bar, pulse, and cards"  
**Status:** ⬜

---

## Dependencies

```
Chunk 1 ──→ Chunk 4 ──→ Chunk 5
       ↓         ↑
Chunk 2 ──┬─────┘
       ↓
Chunk 3 ──┘
```

**Chunk 2 and 3** can be done in any order.  
**Chunk 4** ties them all together.  
**Chunk 5** is final integration.

---

## Implementation Notes

**Reusing Existing Components:**
- `AIReportSheet` → Works for single project
- `MultiProjectAIReport` → New model for option 2
- `AppViewModel.generateAIReport()` → Works for single
- Need: `AppViewModel.generateMultiProjectAIReport()` for option 2

**Navigation:**
- `@State private var showAIActionMenu = false` in MainTabView
- `@State private var showMultiProjectReport = false` in PulseView
- `@State private var showAIReport = false` in PulseProjectCard

---

## Ready to Start?

**Confirm to begin Chunk 1 (Nav Bar AI Button)?**
