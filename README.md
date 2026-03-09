# StackPulse Monitor 📊🔍

Your personal tech stack health monitor with AI-powered insights. Track dependencies, detect vulnerabilities, and get intelligent analysis through natural conversation.

![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)

---

## ✨ Features

### 🤖 AI-Powered Chat Assistant
- **Natural Language Queries** - Ask about your stack in plain English
- **Voice-to-Text** - Tap the mic, speak your questions
- **Persistent Threads** - Continue conversations across sessions
- **Quick Prompts** - "What's my health score?" "Show critical updates" etc.
- **Streaming Responses** - Real-time AI-generated answers
- **Per-Project Context** - AI knows your dependencies

### 📦 Multi-Project Support
- **GitHub Integration** - Import repos with automatic dependency detection
- **Manual Projects** - Track custom stacks and legacy imports
- **Project Health Scores** - Individual 0-100 scores per project
- **Cross-Project Insights** - AI analyzes across all your codebases

### 📊 Health Dashboard
- **Stack Health Score** - 0-100 aggregate score across all projects
- **Status Breakdown**:
  | Status | Icon | Meaning |
  |--------|------|---------|
  | ✅ OK | checkmark.circle | Current and secure |
  | ⚠️ Update | arrow.up.circle | Update available |
  | 🔴 Critical | exclamationmark.shield | CVEs found |
  | ⏰ EOL | clock | End of life approaching |
- **Dependency Summary** - Total, outdated, unknown counts
- **Last Checked** - Time since last sync

### 🔒 Vulnerability Detection
- **OSV Database** - Open Source Vulnerabilities database integration
- **CVE Lookup** - Automatically fetches vulnerability details
- **Severity Scoring** - Critical, High, Medium, Low classifications
- **Fixed Version Info** - See which version patches CVEs

### ⏰ End of Life Tracking
- **endoflife.date API** - Real-time EOL status
- **Lifecycle Dates** - Pre-planned upgrade paths
- **Version Support** - Current, LTS, Extended support tracking
- **Breaking Changes** - Flag for major version updates

### 🤖 AI-Powered Analysis
- **Dependency Analysis** - AI reads changelogs and release notes
- **Urgency Scoring** - AI determines upgrade priority
- **Breaking Change Detection** - AI flags potential issues
- **Score Impact** - -10 to 0 health score impact prediction

### 🚨 Smart Alerts
- **Critical Vulnerabilities** - Immediate notifications
- **Breaking Changes** - Pre-upgrade warnings
- **EOL Warnings** - Lifecycle reminders
- **Update Available** - Routine maintenance
- **Snooze/Dismiss** - Flexible alert management

---

## 🏗️ Architecture

```
StackPulseMonitor/
├── StackPulseMonitorApp.swift          # App entry point
├── ContentView.swift                    # Navigation flow (Onboarding → Main)
├── Config.swift                         # Environment settings
├── Models/
│   ├── Project.swift                    # Project-centric data model
│   ├── Dependency.swift                 # Dependency within projects
│   ├── AIThread.swift                   # Chat thread persistence
│   ├── AIMessage.swift                  # Chat message model
│   ├── Technology.swift                 # Legacy stack item (migration support)
│   ├── TechAlert.swift                  # Alert/notification model
│   └── APIResponses.swift               # Network response models
├── Services/
│   ├── NetworkService.swift             # NPM, GitHub, OSV APIs
│   ├── GitHubAuthService.swift          # GitHub OAuth flow
│   ├── SpeechRecognizer.swift          # Voice-to-text
│   └── StorageService.swift             # Local persistence (UserDefaults/Keychain)
├── ViewModels/
│   └── AppViewModel.swift               # App state management
├── Views/
│   ├── SplashView.swift                 # Launch screen
│   ├── OnboardingView.swift             # First-time walkthrough
│   ├── APIKeySetupView.swift            # OpenAI key entry
│   ├── StackSetupView.swift             # Initial project/stack setup
│   ├── ProjectListView.swift            # Manage projects
│   ├── ProjectDetailView.swift          # Project-specific dependency view
│   ├── AI/
│   │   ├── AIThreadListView.swift        # All chat threads overview
│   │   ├── AIChatView.swift             # Individual chat thread
│   │   ├── ChatInputBar.swift           # Message input + voice button
│   │   └── AIReportSheet.swift          # AI analysis reports
│   ├── MainTabView.swift                # Tab container (Pulse, Projects, AI, Alerts, Settings)
│   ├── PulseView.swift                  # Health dashboard (empty state shows "Add Project")
│   ├── AlertsView.swift                 # Alert center
│   └── SettingsView.swift               # App settings
└── Utilities/
    ├── Theme.swift                      # App styling
    └── Extensions.swift                 # Helper extensions
```

---

## 🚀 Getting Started

### Prerequisites
- **macOS 14.0+**
- **Xcode 15.0+**
- **iOS 17.0+** device or simulator
- **OpenAI API key** (optional, for AI chat/analysis)
- **GitHub account** (optional, for repo import)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/aiagentmackenzie-lang/stackpulse-monitor.git
   cd stackpulse-monitor
   ```

2. **Open in Xcode**
   ```bash
   open StackPulseMonitor.xcodeproj
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd+R` to build and run

### Initial Setup

1. **Complete Onboarding** - Quick feature walkthrough
2. **Add OpenAI Key** (optional) - For AI chat and analysis
3. **Import from GitHub** (optional) - Authenticate and select repos
4. **Configure Your Stack** - Select presets or add custom tech
5. **Start Monitoring** - View health scores and sync data

---

## 📱 Screens

### Pulse View (Dashboard)
- **Health Score** - Circular progress with 0-100 score
- **Status Breakdown** - Up-to-date, Updates, Critical counts
- **Project Cards** - Quick access to project health
- **Critical Banner** - Immediate action required
- **Empty State** - "+ Add Project" button (navigates to Projects)

### Projects View
- **Project List** - All imported and manual projects
- **GitHub Repos** - Auto-imported with dependency detection
- **Manual Projects** - Custom stacks and legacy imports
- **Health Badges** - Score and status per project
- **Delete** - Trash icon to remove projects (persists!)

### Project Detail View
- **Health Score** - Project-specific 0-100 score
- **Dependency List** - Current vs latest version
- **Check Updates** - Refresh dependency status
- **AI Reports** - Historical AI analyses
- **Ask AI** - Navigate to project-specific chat

### AI Chat
- **Thread List** - All conversation history
- **New Thread** - Start fresh conversation
- **Quick Prompts** - Pre-built questions
- **Voice Input** - Mic button for speech-to-text
- **Streaming Responses** - Real-time AI generation
- **Message History** - Persistent across sessions

### Alerts View
- **Filter by Type**: Critical, Update, EOL, Breaking
- **Mark as Read/Unread**
- **Snooze Alerts** - Set reminders
- **Dismiss Alerts** - Clear resolved issues
- **Unread Count** - Badge on tab

### Technology Detail
- **Version Comparison** - Current vs Latest
- **Vulnerability List** - CVE IDs + summaries
- **Release Notes** - Scrollable change log
- **AI Analysis** (requires OpenAI key):
  - What's Changed
  - Is it Urgent
  - What to Do
  - Breaking Changes
  - Score Impact

### Settings
- **OpenAI Key** - Add/remove GPT-4o access
- **GitHub Authentication** - Connect/disconnect GitHub account
- **Notification Preferences**
- **Sync Frequency**
- **Data Export** - JSON stack backup

---

## 🎨 Design System

### Dark Theme
- **Background**: Near-black (`#0A0A0A`)
- **Card Background**: (`#1A1A1A`)
- **Accent**: Sky Blue (`#38BDF8`)
- **AI Accent**: Purple (`#9B6DFF`)

### Status Colors
| Status | Color | Hex |
|--------|-------|-----|
| OK | Green | `#10B981` |
| Update | Yellow | `#F59E0B` |
| Critical | Red | `#EF4444` |
| EOL | Purple | `#8B5CF6` |
| Unknown | Gray | `#6B7280` |

### Typography
- Clean sans-serif system fonts
- Monospace for version numbers
- Bold headings, secondary for metadata

---

## 🛠️ Technical Stack

| Component | Technology |
|-----------|------------|
| Framework | SwiftUI |
| Language | Swift 6.0+ |
| Architecture | MVVM with `@Observable` |
| Networking | URLSession |
| Speech | Speech framework (SFSpeechRecognizer) |
| Auth | ASWebAuthenticationSession (GitHub OAuth) |
| State | `@Observable` pattern |
| Persistence | UserDefaults + Keychain |

---

## 🌐 API Integrations

### NPM Registry
```
GET https://registry.npmjs.org/{package}/latest
GET https://registry.npmjs.org/-/v1/search?text={query}
```

### GitHub API
```
GET https://api.github.com/repos/{owner}/{repo}/releases/latest
GET https://api.github.com/repos/{owner}/{repo}/contents/{path}
```

### GitHub OAuth
```
https://github.com/login/oauth/authorize
https://github.com/login/oauth/access_token
```

### OSV Vulnerability Database
```
POST https://api.osv.dev/v1/query
```

### End of Life API
```
GET https://endoflife.date/api/{technology}.json
```

### OpenAI (Optional)
```
POST https://api.openai.com/v1/chat/completions
Model: gpt-4o
```

---

## 📦 Preset Technologies

### Frontend
- React, React Native, Next.js, Vue, Angular, Svelte, TypeScript, Tailwind CSS

### Backend
- Node.js, NestJS, Express, Django, FastAPI, Laravel, Ruby on Rails

### Database
- PostgreSQL, MongoDB, Redis, MySQL, Prisma, Supabase, Firebase

### DevOps
- Docker, Kubernetes, GitHub Actions, Vercel, AWS, Nginx, Terraform

### Languages
- Python, Go, Rust, Java, PHP, Ruby, Swift, Kotlin

---

## 🔐 Security

### Data Storage
- **Stack Data** - UserDefaults (device-local)
- **OpenAI Key** - iOS Keychain (secure)
- **GitHub Token** - Keychain (secure)
- **No Server** - All APIs client-side

### GitHub Permissions
- **Read-only repos** - Public/private repo access
- **No write access** - Cannot modify code
- **Token stored locally** - Never leaves device

### API Risks
- NPM registry - Public data only
- GitHub API - Subject to rate limits (auth increases limits)
- OSV - Security-focused database
- EOL API - Open community project

---

## 📊 Health Scoring

### Calculation Factors
- ✅ Up-to-date items: +positive
- ⚠️ Updates available: -minor
- 🔴 Critical CVEs: -major
- ⏰ Near EOL: -moderate
- 💥 Breaking changes: -high

### Score Ranges
| Score | Status | Action |
|-------|--------|--------|
| 80-100 | Healthy | Maintain |
| 60-79 | Needs Attention | Review updates |
| 0-59 | Critical | Immediate action |

---

## 🔊 Voice-to-Text

### Setup
- **iOS Settings** → **Privacy & Security** → **Microphone** → Allow StackPulse
- **iOS Settings** → **Privacy & Security** → **Speech Recognition** → Allow StackPulse

### Usage
1. Navigate to AI Chat
2. Select a project
3. Tap **mic button** (red when recording)
4. Speak your question
5. Tap mic again to stop
6. Text auto-sends to AI

### Limitations
- Requires physical device (not simulator)
- Requires internet connection
- iOS 17.0+ only

---

## 🐛 Troubleshooting

### "Rate Limited" Error
- GitHub API has limits
- Authenticate with GitHub for higher limits
- Wait and retry

### AI Summary Not Working
- Check OpenAI key validity
- Ensure sufficient API credits
- Key stored in Settings → API Key

### Voice-to-Text Not Working
- Check microphone permissions
- Check speech recognition permissions
- Requires physical device (not simulator)

### Tech Not Found
- Check package name (case-sensitive for NPM)
- Try searching first
- Add manually with version

### Sync Stuck
- Check internet connection
- Some APIs may be slow
- Tap refresh to retry

### Deleted Projects Reappearing
- Fixed in latest build
- Ensure you're on main branch
- Delete → force quit → reopen should persist

---

## 🤝 Contact & Support

Designed by **Raphael Main** and **Agent Mackenzie**.

For questions, feedback, or collaboration:

**📧 Email:** aiagent.mackenzie@gmail.com

---

## 🙏 Acknowledgments

- [NPM Registry](https://registry.npmjs.org) - Package data
- [Open Source Vulnerabilities (OSV)](https://osv.dev) - Security database
- [endoflife.date](https://endoflife.date) - EOL tracking
- [GitHub API](https://docs.github.com/en/rest) - Release data
- [OpenAI](https://openai.com) - GPT-4o AI summaries
- Icons by [SF Symbols](https://developer.apple.com/sf-symbols/)

---

## 📝 License

**Copyright © 2026 Raphael. All rights reserved.**

This software is proprietary and confidential. No part of this project may be used, copied, modified, distributed, or reproduced without explicit written permission from the owner.

---

<p align="center">
  <strong>StackPulse</strong> — 
  <em>Know Your Stack's Pulse</em> 📊
</p>
