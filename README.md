# StackPulse Monitor 📊🔍

Your personal tech stack health monitor. Track dependencies, detect vulnerabilities, and stay ahead of end-of-life dates with AI-powered insights.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

---

## ✨ Features

### 📦 Multi-Package Registry Support
- **NPM Registry** - Direct package lookup and version checking
- **GitHub Releases** - Track releases from GitHub repos
- **Platform Monitoring** - Node.js, Python, Go, PostgreSQL, and more
- **Language Support** - EOL tracking for major languages

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

### 🤖 AI-Powered Insights
- **GPT-4o Analysis** - Summarize what's changed between versions
- **Urgency Scoring** - AI determines upgrade priority
- **Breaking Change Detection** - AI flags potential issues
- **Score Impact** - -10 to 0 health score impact prediction

### 📊 Health Dashboard
- **Stack Health Score** - 0-100 aggregate score
- **Status Breakdown**:
  | Status | Icon | Meaning |
  |--------|------|---------|
  | ✅ OK | checkmark.circle | Current and secure |
  | ⚠️ Update | arrow.up.circle | Update available |
  | 🔴 Critical | exclamationmark.shield | CVEs found |
  | ⏰ EOL | clock | End of life approaching |

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
├── ContentView.swift                    # Navigation flow
├── Config.swift                         # Environment settings
├── Models/
│   ├── Technology.swift                 # Tech stack item model
│   ├── TechAlert.swift                  # Alert/notification model
│   ├── PresetTech.swift                 # Pre-configured tech list
│   └── APIResponses.swift               # Network response models
├── Services/
│   ├── NetworkService.swift             # NPM, GitHub, OSV APIs
│   └── StorageService.swift             # Local persistence
├── ViewModels/
│   └── AppViewModel.swift               # App state management
├── Views/
│   ├── SplashView.swift                 # Launch screen
│   ├── OnboardingView.swift            # First-time walkthrough
│   ├── APIKeySetupView.swift           # OpenAI key entry
│   ├── StackSetupView.swift            # Initial stack setup
│   ├── MainTabView.swift               # Tab container
│   ├── StackView.swift                 # Manage tech stack
│   ├── PulseView.swift                 # Health dashboard
│   ├── AlertsView.swift                 # Alert center
│   ├── SettingsView.swift               # App settings
│   └── TechnologyDetailView.swift       # Tech details + AI summary
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
- **OpenAI API key** (optional, for AI summaries)

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
2. **Add OpenAI Key** (optional) - For AI-powered summaries
3. **Configure Your Stack** - Select from presets or add custom tech
4. **Start Monitoring** - Tap refresh to sync all data

---

## 📱 Screens

### Pulse View (Dashboard)
- **Health Score** - Circular progress with 0-100 score
- **Status Breakdown** - Up-to-date, Updates, Critical counts
- **Tech Status Cards** - Latest version + AI summary
- **Critical Banner** - Immediate action required
- **AI Key Reminder** - Prompt if not configured
- **Pull to Refresh** - Sync entire stack

### Stack View
- **Category Grouping**:
  - Frontend
  - Backend
  - Database
  - DevOps
  - Language
- **Expand/Collapse** Categories
- **Tech Cards** - Version + status at a glance
- **Add Technology** - Search NPM or manual entry

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
- **AI Summary** (requires OpenAI key):
  - What's Changed
  - Is it Urgent
  - What to Do
  - Breaking Changes
  - Score Impact

### Settings
- **OpenAI Key** - Add/remove GPT-4o access
- **Notification Preferences**
- **Sync Frequency**
- **Data Export** - JSON stack backup

---

## 🎨 Design System

### Dark Theme
- **Background**: Near-black (`#0A0A0A`)
- **Card Background** (`#1A1A1A`)
- **Accent**: Sky Blue (`#38BDF8`)

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
| Language | Swift 5.9+ |
| Architecture | MVVM |
| Networking | URLSession |
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
- React, React Native, Next.js, Vue, Expo, TypeScript

### Backend
- Node.js, NestJS, Express, Django, FastAPI, Laravel

### Database
- PostgreSQL, MongoDB, Redis, MySQL, Prisma, Supabase

### DevOps
- Docker, Kubernetes, GitHub Actions, Vercel, AWS, Nginx

### Languages
- Python, Go, Rust, Java, PHP, Ruby

---

## 🔐 Security

### Data Storage
- **Stack Data** - UserDefaults (device-local)
- **OpenAI Key** - iOS Keychain (secure)
- **No Server** - All APIs client-side

### API Risks
- NPM registry - Public data only
- GitHub API - Subject to rate limits
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

## 🐛 Troubleshooting

### "Rate Limited" Error
- GitHub API has limits
- Add a GitHub token in Settings

### AI Summary Not Working
- Check OpenAI key validity
- Ensure sufficient API credits
- Key stored in Settings → API Key

### Tech Not Found
- Check package name (case-sensitive for NPM)
- Try searching first
- Add manually with version

### Sync Stuck
- Check internet connection
- Some APIs may be slow
- Tap refresh to retry

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

MIT License - free for personal and commercial use.

---

<p align="center">
  <strong>StackPulse</strong> — 
  <em>Know Your Stack's Pulse</em> 📊
</p>
