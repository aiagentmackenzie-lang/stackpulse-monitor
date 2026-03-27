# Plan: Fix StackPulse GitHub Import Issues

**Created:** 2026-02-28 21:36
**Project:** StackPulse-GitHub
**Issues:** Multi-select broken, scroll broken, no re-import option

---

## Problem Statement

3 Critical UI/UX Issues:

1. **Multi-select NOT working** — Only 1 repo can be selected despite UI showing checkboxes
2. **Scroll NOT working** — Repo list doesn't scroll, stuck showing first ~5 repos  
3. **No re-import option** — After importing once, can't access GitHub import again

---

## Chunk 1: Diagnose Multi-Select Logic (⏱️ 3 min) ⬜

**Spec:**
- [ ] Review GitHubAuthUI.swift selection logic
- [ ] Identify why only 1 selection works
- [ ] Check selectedRepos Set<Int> usage
- [ ] Verify toggleSelection function

**Files:**
- `StackPulseMonitor/Views/GitHubAuthUI.swift`

**Expected Fix:**
- Selection state persists for multiple repos
- Each tap toggles selection independently
- Multiple repos highlighted

**Test:** Build + run, tap multiple repos, all should show checkmarks

---

## Chunk 2: Fix List Scroll (⏱️ 4 min) ⬜

**Spec:**
- [ ] Add proper List frame constraints
- [ ] Ensure ScrollView wrapper or .scrollable
- [ ] Fix layout that blocks scrolling
- [ ] Test with 30+ items

**Files:**
- `StackPulseMonitor/Views/GitHubAuthUI.swift`

**Expected Fix:**
- Smooth scrolling through all 30 repos
- No cutoff at bottom
- Bounce/easing works

**Test:** Scroll through entire repo list, verify all repos accessible

---

## Chunk 3: Add Persistent Import Button (⏱️ 5 min) ⬜

**Spec:**
- [ ] Add "Add from GitHub" button to main StackSetupView
- [ ] Show when authService.isAuthenticated = true
- [ ] Keep existing "Import from Repos" button too
- [ ] Button opens sheet with repo list

**Files:**
- `StackPulseMonitor/Views/StackSetupView.swift`

**Expected Fix:**
- Button visible on main Add Tech screen
- Opens GitHub repo picker
- Can import multiple times
- Works after initial onboarding

**Test:** Import once, return to main screen, tap "Add from GitHub", import again

---

## Chunk 4: Test Multi-Import Flow (⏱️ 3 min) ⬜

**Spec:**
- [ ] Select 3+ repos at once
- [ ] Tap Import
- [ ] Verify all repos added to stack
- [ ] Repeat import process
- [ ] Verify no duplicates or crashes

**Files:**
- Same as above

**Expected:**
- Multiple repos import together
- Selection clears after import
- Can repeat the flow
- Stack shows all imported repos

---

## Chunk 5: Commit & Push (⏱️ 2 min) ⬜

**Spec:**
- [ ] All 3 issues fixed
- [ ] Build passes
- [ ] Commit with descriptive message
- [ ] Push to GitHub

**Commit Message:**
```
fix(ui): GitHub import multi-select, scroll, and re-import

- Fix multi-select: toggleSelection now properly tracks multiple repos
- Fix scroll: add proper List constraints for smooth scrolling
- Add persistent "Add from GitHub" button to StackSetupView
- Users can now import multiple repos multiple times
```

---

## Progress Tracker

| Chunk | Issue | Time | Status | Commit |
|-------|-------|------|--------|--------|
| 1 | Multi-select logic | 3 min | ⬜ | - |
| 2 | Scroll fix | 4 min | ⬜ | - |
| 3 | Re-import button | 5 min | ⬜ | - |
| 4 | End-to-end test | 3 min | ⬜ | - |
| 5 | Commit & push | 2 min | ⬜ | - |

**Total Estimated:** 17 minutes
**Actual:** ___ minutes

---

## Current Status
Ready to start. Awaiting verification to proceed with Chunk 1.
