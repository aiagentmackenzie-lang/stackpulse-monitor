# Plan: PulseView Project Dashboard Redesign

**Created:** 2026-03-02 13:16  
**Project:** StackPulse Monitor iOS  
**Estimated Time:** 15 minutes  
**Max Chunk Time:** 5 minutes  

---

## Progress Update

| Chunk | Task | Status | Time |
|-------|------|--------|------|
| **1** | ProjectCard component with health score | ✅ Complete | 3 min |
| **2** | ProjectDetailView with "Check for Updates" | ✅ Complete | 4 min |
| **3** | Refactor PulseView to Project Dashboard | 🔄 In Progress | — |

---

## Chunk 1 ✅ Complete

**File:** `StackPulseMonitor/Views/Components/PulseProjectCard.swift`

**Delivered:**
- Health score calculation: up-to-date / checked deps * 100
- Color coding: red (<50%), orange (50-80%), green (>80%)
- Stats: total deps, outdated count, unknown count
- Last checked timestamp
- Build: ✅ Succeeded
- Commit: `8e05755`

---

## Chunk 2 ✅ Complete

**File:** `StackPulseMonitor/Views/ProjectDetailView.swift`

**Delivered:**
- Header with large health score and progress bar
- "Check for Updates" button with progress indicator
- Dependencies grouped by category
- Individual dependency rows with status icons
- Version comparison: current → latest
- Stat badges: Total, Outdated, Unknown
- Build: ✅ Succeeded
- Note: Renamed DependencyRow to ProjectDetailDependencyRow to avoid conflict

---

## Chunk 3 🔄 Ready to Start

**File:** `StackPulseMonitor/Views/PulseView.swift` (refactor)

**Spec:**
- Replace flat `allDependencies` list with project cards
- Use `PulseProjectCard` with tap handler
- Navigation to `ProjectDetailView` via `NavigationStack`
- Keep empty state
- Update navigation flow

**Status:** Ready to execute

**Time Estimate:** 4 minutes

---

## Commit Chunk 2 Now...
