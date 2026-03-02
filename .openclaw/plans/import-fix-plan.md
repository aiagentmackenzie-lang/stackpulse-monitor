# Plan: StackPulse Import Issues Fix
Created: 2026-03-02 10:43
Project: /Users/main/.openclaw/workspace/StackPulse-GitHub

## Problem Summary
Two import flows exist with different behaviors:
1. StackView flow: Has preview but shows 42 files (should show only manifests)
2. Onboarding flow: No preview at all, imports directly

## Root Cause Analysis Needed
- `detectDependencyFiles()` should filter to only manifest files (package.json, requirements.txt, etc.)
- Current behavior suggests filter not working or wrong data passed to UI
- Onboarding calls `GitHubRepoListView` directly without preview wrapper

## Chunk 1: Diagnose File Filtering (5 min)
**Spec:** Add comprehensive logging to understand what GitHub API returns vs what gets filtered
- Add logs to `detectDependencyFiles()` to see raw API response
- Add logs to see filtered results
- Add logs to Preview UI to see what data it receives
- Rebuild and test to identify exact failure point

**Verification:** Logs reveal whether issue is in API response, filtering logic, or UI display

## Chunk 2: Fix File Filtering (5 min)
**Spec:** Ensure only manifest files pass through
- Verify `dependencyFilenames` array contains correct names
- Check filter logic matches exact filenames (not substrings)
- Ensure no directory traversal logic interferes
- Rebuild and verify only manifests show

**Verification:** Preview shows "1 file: package.json" not "42 files"

## Chunk 3: Add Preview to Onboarding (5 min)
**Spec:** StackSetupView should use same preview flow as StackView
- Find where StackSetupView calls GitHubRepoListView
- Wrap in same ImportPreviewView pattern
- Ensure single source of truth for import logic
- Rebuild and test onboarding flow

**Verification:** Onboarding shows Preview screen before importing

## Chunk 4: Consolidate Import Logic (5 min)
**Spec:** Both flows use same import pathway
- Extract shared import coordinator
- Ensure classification runs in both flows
- Add error handling for failed imports
- Clean up duplicate code

**Verification:** Both onboarding and StackView flows behave identically

## Current Status
Chunk 1: Not started ❌
Chunk 2: Not started ❌
Chunk 3: Not started ❌
Chunk 4: Not started ❌
