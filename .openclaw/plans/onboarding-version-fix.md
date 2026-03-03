# Plan: Onboarding Version Input Fix
Branch: polish
Priority: CRITICAL

---

## Chunk 1: Analyze Current ManualEntryView (⏱️ 3 min)
**Spec:** Read current implementation to understand how manual dependencies are added

**Files:** `StackPulseMonitor/Views/Onboarding/ManualEntryView.swift`

**Questions to answer:**
- How is dependency name captured?
- Where is Dependency created?
- What fields are set?
- Is version currently captured anywhere?

---

## Chunk 2: Add Version Input to ManualEntryView (⏱️ 5 min)
**Spec:** Add optional version field alongside dependency name

**Changes:**
- Add @State for version input
- Add TextField for version (placeholder: "e.g., 1.2.3 (optional)")
- Style to match existing design
- Add validation hint about health check

---

## Chunk 3: Update Dependency Creation (⏱️ 3 min)
**Spec:** Pass version when creating Dependency

**Changes:**
- Modify addManualDependency to accept optional version
- Set currentVersion from input
- Validate version format (semver-ish)

---

## Chunk 4: Update Onboarding Flow (⏱️ 4 min)
**Spec:** Ensure version flows through onboarding to storage

**Changes:**
- Check where ManualEntryView is called
- Verify version persists to Project/Dependency
- Test health check runs with version

---

## Chunk 5: Visual Polish (⏱️ 3 min)
**Spec:** Add visual indicator for missing version

**Changes:**
- In Projects list, show warning icon if dependency has no version
- Tooltip: "Add version for health check"
- Optional: "Set version" quick action

---

## Total: 18 minutes
## Files Modified: 3-4
## Tests: Fresh install flow, health check with manual entry
