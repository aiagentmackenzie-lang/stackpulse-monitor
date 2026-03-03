# Plan: GitHub README Context for AI
Branch: polish
Priority: HIGH

## Root Cause
AI chat only sees dependencies, not project purpose from README/description.

## Changes

### Chunk 1: Add AI Context to Project Model (⏱️ 5 min)
**File:** Models/Project.swift

Add fields:
- `aiContext: String?` - README excerpt + description
- `projectDescription: String?` - GitHub repo description
- `topics: [String]` - GitHub topics/tags

### Chunk 2: Update GitHub Importer (⏱️ 10 min)
**File:** Services/GitHubAuthService.swift

Add methods:
- `fetchRepositoryReadme(owner:repo:token:)` → returns first 2000 chars
- `fetchRepositoryDetails(owner:repo:token:)` → description, topics, language

### Chunk 3: Populate AI Context on Import (⏱️ 5 min)
**File:** StackSetupView.swift GitHub import flow (~line 250)

After detecting deps:
- Fetch README and metadata
- Store in Project.aiContext
- Truncate to fit in prompts

### Chunk 4: Update AI Prompts (⏱️ 5 min)
**File:** Services/AIContextBuilder.swift or AI chat views

Include in prompts:
```
Project: {name}
Description: {description}
Context: {aiContext}
Dependencies: {list}

User question about dependencies...
```

### Chunk 5: Test AI Context (⏱️ 5 min)
**Test:** Import repo with good README, ask AI "What does this project do?"

## Total: 30 minutes
## Test: GitHub import with README → AI chat references project purpose
