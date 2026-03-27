# Plan: StackPulse Project-Centric Architecture
Created: 2026-03-02 11:02
Status: Proposed - needs user confirmation

## Current Problems
1. Dependencies are flat orphans — no link to parent repository
2. Deleting repo leaves "ghost" dependencies behind
3. No way to see "what's in this project?"
4. No hierarchy makes large projects unmanagable

## Proposed Solution: Project-Centric Data Model

### Data Model Changes

**New: Project Entity (replaces flat stack)**
```swift
struct Project: Identifiable, Codable {
    let id: UUID
    let name: String                    // "leap lexi"
    let source: ProjectSource           // .github, .manual
    let githubFullName: String?         // "user/leap-lexi"
    let importedAt: Date
    var isExpanded: Bool                // UI state
    var dependencies: [Dependency]      // Nested children
}

struct Dependency: Identifiable, Codable {
    let id: UUID
    let name: String                    // "react"
    let type: TechType                  // .npm, .pypi
    let category: TechCategory          // Frontend
    let currentVersion: String
    let latestVersion: String?
    let parentProjectId: UUID           // Link to parent
    let isOutdated: Bool                // Auto-calculated
}
```

### UI Changes: Hierarchical View

**Stack View becomes Project List:**
```
📱 Stack Pulse

Projects (3)
├── ▼ leap lexi [GitHub]
│   ├── react ^18.2.0 → 18.3.1 ⚠️
│   ├── express ✓ 4.18.0 
│   └── mongoose ✓ 6.0.0
├── ▶ AgroVision
└── ▶ portfolio-site

+ Import Project
```

**Features:**
- Expand/collapse projects to see dependencies
- Each dependency shows: name, type badge, version, outdated indicator
- Tap dependency → see details + update options
- Tap project → edit/delete project (with "delete dependencies too?" option)
- Import adds project with nested dependencies

### Migration from Current Model

**Option 1: Full Migration (Recommended)**
- Keep `Technology` for global library reference
- Create new `Project` model for imports
- Flat deps become orphaned (user can manually re-import)

**Option 2: Hybrid**
- Add `parentRepoId` to existing `Technology`
- Group by `parentRepoId` in UI
- Supports both flat (manual adds) and grouped (imports)

### Implementation Phases

**Phase 1: Data Model (15 min)**
- Add `Project` + `Dependency` models
- Update `AppViewModel` to use `projects: [Project]`
- Simple migration: existing stack becomes "orphan" project

**Phase 2: Hierarchical UI (20 min)**
- Replace flat list with expandable project cards
- Add expand/collapse animation
- Show dependency count badges on collapsed projects
- Group dependencies under projects visually

**Phase 3: Link Dependencies to Projects (10 min)**
- Import flow creates Project + nested dependencies
- Delete project modal: "Delete project only" or "Delete with dependencies"
- Edit project: rename, re-scan for deps

**Phase 4: Polish (10 min)**
- Outdated indicators on dependencies
- Filter: show all / show outdated / show by project
- Search within project

**Total: ~55 minutes**

### Tradeoffs

**Pros:**
- Logical project-per-repo grouping
- Deleting repo cleans up all its deps
- Better scale for multiple projects
- Clear "where did this come from?"

**Cons:**
- Breaking change (existing data migration)
- More complex UI (expandable sections)
- More state management

### Alternative: Quick Fix (No Architecture Change)

**Immediate band-aid:**
- Add repo name prefix to dependencies: "leap-lexi:react"
- Delete modal: "Also delete X dependencies from this repo?"
- Group by repo name in flat list

**Time: 10 minutes**
**Pros:** Quick, doesn't break existing
**Cons:** Still flat, still hacky

---

## Decision Needed

**Option A: Full Project-Centric Refactor (~1 hour)**
Benefit: Proper architecture, scales well
Risk: Breaking change, extensive testing

**Option B: Band-aid Grouping (~10 min)**  
Benefit: Quick fix, no migration
Risk: Still messy long-term

Which do you want? I recommend **Option A** for a real product, but happy to do **Option B** if you want something now.
