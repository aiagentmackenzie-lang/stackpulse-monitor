# StackPulse GitHub Import — Current State & Next Steps

**Date:** 2026-02-28  
**Session:** OAuth working, but smart import not functional  
**Status:** Builds pass, but classification logic broken

---

## 🚨 Critical Issues Identified

### Issue 1: Dependency Classification Shows "Unknown"
**Problem:** When repos are imported, dependencies are detected but show invalid/unknown types.

**Expected:**  
- express → Type: NPM, Category: Backend  
- react → Type: NPM, Category: Frontend  
- python-requests → Type: PyPI, Category: Backend

**Current:** Shows generic .language type with no useful classification

**Root Cause:**
- `TechType` enum too limited: only `.npm`, `.github`, `.language`, `.platform`  
- No intelligent categorization based on package name patterns  
- No mapping of ecosystem → proper type/category

---

### Issue 2: Manual Selection Required for Proper Stack Setup
**Problem:** App only sets up correct stack if user manually selects from presets. GitHub import bypasses all intelligence.

**Expected:** GitHub import should:  
1. Detect repo language (Python, JS, Go, Rust, Java)  
2. Classify dependencies (frontend vs backend vs database)  
3. Auto-categorize (Frontend, Backend, Database, DevOps)  
4. Show proper health monitoring for each

**Current:** Just dumps repo names + raw dependencies with no context

---

### Issue 3: No Deduction Logic
**Problem:** App doesn't "understand" what technologies do.

**Examples:**  
- `express` should know it's a **backend framework**  
- `react` should know it's a **frontend library**  
- `mongodb` should know it's a **database**

**Missing:** Large lookup table / ML classification for common packages

---

## 📝 Proposed Solution Plan

### Phase 1: Fix TechType Classification (2-3 hours)

**Task 1.1: Expand TechType Enum**
```swift
enum TechType {
    case npm          // Node packages
    case pypi         // Python packages  
    case cargo        // Rust crates
    case goMod        // Go modules
    case maven        // Java/Maven
    case gradle       // Java/Gradle
    case gem          // Ruby gems
    case composer     // PHP packages
    case github       // Repos
    case language     // Programming languages
    case platform     // Services (AWS, etc)
}
```

**Task 1.2: Create Package Classifier**
- Build lookup table: 10,000+ common packages → {type, category}
- Pattern matching for unknown packages:
  - `*-db`, `*-database` → Database
  - `*-css`, `*-ui`, `react-*` → Frontend  
  - `express-*`, `fastapi`, `django` → Backend

**Task 1.3: Map Ecosystem → TechType**
```swift
.func ecosystemToTechType(_ eco: EcosystemType) -> TechType {
    switch eco {
    case .npm: return .npm
    case .pypi: return .pypi
    case .cargo: return .cargo
    // etc
    }
}
```

### Phase 2: Smart Categorization (2-3 hours)

**Task 2.1: Infer Category from Package Name**
```swift
func inferCategory(from name: String, type: TechType) -> TechCategory {
    let lower = name.lowercased()
    if lower.contains("react") || lower.contains("vue") || lower.contains("angular") {
        return .frontend
    }
    if lower.contains("express") || lower.contains("fastapi") || lower.contains("django") {
        return .backend
    }
    if lower.contains("mongo") || lower.contains("postgres") || lower.contains("redis") {
        return .database
    }
    // ... more patterns
    return .other
}
```

**Task 2.2: Create Knowledge Database**
- `TechnologyKnowledge.swift` with known packages
- Categories: Frontend, Backend, Database, DevOps, Mobile, AI/ML
- Include version compatibility data

### Phase 3: Enhanced Import Flow (2 hours)

**Task 3.1: Show Detection Progress**
- "Scanning AgroVision..."
- "Found package.json with 12 dependencies"
- "Classifying technologies..."
- Progress bar during import

**Task 3.2: Post-Import Summary**
- Show what was detected: "Added 15 technologies"
- Group by category: "5 Frontend, 8 Backend, 2 Database"
- Allow user to remove/adjust before saving

**Task 3.3: One-Click Full Analysis**
- "Analyze All Repos" button
- Auto-import + auto-classify in one step
- Generate full stack report

### Phase 4: Repository Intelligence (3-4 hours)

**Task 4.1: Detect Primary Language**
- Read GitHub API `language` field
- Fallback: scan file extensions in repo
- Weight by line count

**Task 4.2: Detect Framework**
- Look for framework indicators:
  - `next.config.js` → Next.js
  - `vite.config` → Vite
  - `tailwind.config` → Tailwind
  - `Cargo.toml` dependencies → Actix, Axum, etc

**Task 4.3: Health Score per Technology**
- Check npm: outdated, vulnerable, deprecated
- Check pypi: outdated, security alerts
- Version diff: current vs latest

---

## 🎯 Tomorrow's Priority Order

| Priority | Task | Time | Impact |
|----------|------|------|--------|
| **P1** | Expand TechType enum + ecosystem mapping | 45 min | **Critical** — fixes "unknown" issue |
| **P2** | Create basic package classifier (top 500) | 90 min | **High** — proper categorization |
| **P3** | Fix TechCategory inference logic | 45 min | **High** — frontend/backend detection |
| **P4** | Add import progress UI | 30 min | Medium — better UX |
| **P5** | Test end-to-end with AgroVision/Prodigy | 30 min | Verify fixes |

**Total:** ~4.5 hours of focused work

---

## 📂 Current Code Locations

| Component | File | Status |
|-----------|------|--------|
| Dependency detection | `GitHubAuthService.swift:347-380` | ✅ Working |
| Dependency parsing | `GitHubAuthService.swift:380-500` | ✅ Working |
| Import handler | `StackView.swift:388-425` | ✅ Working |
| TechType enum | `Technology.swift` | ⚠️ Too limited |
| Classification logic | `StackView.swift` | ❌ Missing |

---

## 🔧 Quick Fix Ideas (for tomorrow)

1. **Immediate:** Change default `.language` to proper ecosystem type in import handler
2. **Short-term:** Add 50 most common packages with hardcoded categories
3. **Medium-term:** Build full classifier with pattern matching
4. **Long-term:** Integrate with npm/pypi APIs for metadata

---

## 📝 Notes from Session

- OAuth is solid ✅
- Repo listing works ✅  
- Multi-select works ✅
- Scroll works ✅
- Import adds to stack ✅
- **BUT:** Classification is broken — shows wrong types
- **BUT:** No intelligence about what packages do
- **BUT:** Manual setup works better than import

**Key Insight:** The plumbing is done, but the brain is missing. Need knowledge layer.

---

## Next Session Start

1. Review this file
2. Pick P1 task (TechType expansion)
3. Implement ecosystem → TechType mapping
4. Test with user's actual repos (AgroVision, etc.)
5. Verify proper classification
