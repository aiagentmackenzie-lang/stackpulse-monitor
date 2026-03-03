# Plan: Onboarding Version Input Fix
Branch: polish
Priority: CRITICAL

## Root Cause
StackSetupView only accepts name for custom tech, no version. Results in empty currentVersion when creating Dependencies.

## Changes

### Chunk 1: Add Version State and Input (⏱️ 3 min)
**File:** StackSetupView.swift (~line 130)

Add:
- `@State private var customVersion = ""`
- TextField for version alongside name
- Placeholder: "Version (e.g., 1.2.3) - optional"

### Chunk 2: Update addCustomTech() (⏱️ 2 min)
**File:** StackSetupView.swift (~line 358)

Modify function to:
- Accept and pass version
- Clear version field on add

### Chunk 3: Update Technology Model (⏱️ 3 min)
**File:** Technology.swift

Add version field if missing, ensure Codable compliance.

### Chunk 4: Fix "My Stack" Creation (⏱️ 3 min)
**File:** StackSetupView.swift (~line 179)

Change: `currentVersion: ""` → `currentVersion: tech.currentVersion ?? ""`

### Chunk 5: Update Preset Tech (⏱️ 4 min)
**File:** PresetTech.swift

Add known versions for common presets (React 18.x, Node 20.x, etc.)

## Total: 15 minutes
## Test: Fresh install, add custom tech with version, verify health check runs
