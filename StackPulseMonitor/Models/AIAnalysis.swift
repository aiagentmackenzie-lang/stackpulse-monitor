import Foundation

// MARK: - AI-Powered Project Analysis

/// Complete AI analysis report for a project's dependencies
struct ProjectAIReport: Codable, Identifiable, Equatable {
    let id: UUID
    let projectId: UUID
    let generatedAt: Date
    let summary: String                    // "You have 1 critical and 3 safe updates"
    let criticalUpdates: [AIDependencyInsight]
    let safeUpdates: [AIDependencyInsight]
    let reviewRecommended: [AIDependencyInsight]
    let actionPlan: [String]               // Prioritized steps
    let estimatedTime: String?           // "2 hours including testing"
    let overallRiskScore: Int              // 0-100 (higher = riskier to update)
    
    init(
        id: UUID = UUID(),
        projectId: UUID,
        generatedAt: Date = Date(),
        summary: String,
        criticalUpdates: [AIDependencyInsight],
        safeUpdates: [AIDependencyInsight],
        reviewRecommended: [AIDependencyInsight],
        actionPlan: [String],
        estimatedTime: String? = nil,
        overallRiskScore: Int = 0
    ) {
        self.id = id
        self.projectId = projectId
        self.generatedAt = generatedAt
        self.summary = summary
        self.criticalUpdates = criticalUpdates
        self.safeUpdates = safeUpdates
        self.reviewRecommended = reviewRecommended
        self.actionPlan = actionPlan
        self.estimatedTime = estimatedTime
        self.overallRiskScore = overallRiskScore
    }
    
    var totalAnalyzed: Int {
        criticalUpdates.count + safeUpdates.count + reviewRecommended.count
    }
    
    var hasCritical: Bool { !criticalUpdates.isEmpty }
    var hasSafe: Bool { !safeUpdates.isEmpty }
    var hasReview: Bool { !reviewRecommended.isEmpty }
}

/// Individual dependency AI insight
struct AIDependencyInsight: Codable, Identifiable, Equatable {
    let id: UUID
    let dependencyName: String
    let currentVersion: String
    let latestVersion: String
    let riskLevel: UpdateRiskLevel
    let reason: String                     // Why this classification
    let breakingChanges: Bool
    let securityImpact: String?
    let migrationComplexity: Complexity    // simple/moderate/complex
    let recommendedAction: String           // "Update immediately" / "Safe to batch" / "Test thoroughly"
    
    init(
        id: UUID = UUID(),
        dependencyName: String,
        currentVersion: String,
        latestVersion: String,
        riskLevel: UpdateRiskLevel,
        reason: String,
        breakingChanges: Bool = false,
        securityImpact: String? = nil,
        migrationComplexity: Complexity = .simple,
        recommendedAction: String
    ) {
        self.id = id
        self.dependencyName = dependencyName
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.riskLevel = riskLevel
        self.reason = reason
        self.breakingChanges = breakingChanges
        self.securityImpact = securityImpact
        self.migrationComplexity = migrationComplexity
        self.recommendedAction = recommendedAction
    }
}

enum UpdateRiskLevel: String, Codable, CaseIterable {
    case critical = "Critical"
    case important = "Important"
    case recommended = "Recommended"
    case optional = "Optional"
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .important: return "exclamationmark.circle.fill"
        case .recommended: return "checkmark.circle.fill"
        case .optional: return "minus.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .important: return "orange"
        case .recommended: return "blue"
        case .optional: return "gray"
        }
    }
    
    var priority: Int {
        switch self {
        case .critical: return 0
        case .important: return 1
        case .recommended: return 2
        case .optional: return 3
        }
    }
}

enum Complexity: String, Codable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
    
    var icon: String {
        switch self {
        case .simple: return "1.circle.fill"
        case .moderate: return "2.circle.fill"
        case .complex: return "3.circle.fill"
        }
    }
}

// MARK: - OpenAI Request/Response Models

/// Request to OpenAI for project analysis
struct AIProjectAnalysisRequest: Codable {
    let projectName: String
    let dependencies: [AIDependencyContext]
    let cveData: [String: [String]]          // dep name -> CVE IDs
    let currentStack: String                  // summary of current versions
}

struct AIDependencyContext: Codable {
    let name: String
    let currentVersion: String
    let latestVersion: String
    let type: String                          // npm, pypi, etc
    let category: String                      // frontend, backend, etc
    let changelogSnippet: String?             // First 500 chars
    let cveCount: Int
}

/// Expected response from OpenAI
struct AIProjectAnalysisResponse: Codable {
    let summary: String
    let critical: [AIInsightRaw]
    let safe: [AIInsightRaw]
    let review: [AIInsightRaw]
    let actionPlan: [String]
    let estimatedTime: String?
    let overallRiskScore: Int
}

struct AIInsightRaw: Codable {
    let dependencyName: String
    let riskLevel: String
    let reason: String
    let breakingChanges: Bool
    let securityImpact: String?
    let migrationComplexity: String
    let recommendedAction: String
}

// MARK: - Preview Helpers

extension ProjectAIReport {
    static var preview: ProjectAIReport {
        ProjectAIReport(
            projectId: UUID(),
            summary: "You have 1 critical security update and 3 safe updates",
            criticalUpdates: [
                AIDependencyInsight(
                    dependencyName: "react",
                    currentVersion: "18.2.0",
                    latestVersion: "19.0.0",
                    riskLevel: .critical,
                    reason: "Security vulnerability CVE-2024-1234 affects your current version. Immediate update recommended.",
                    breakingChanges: true,
                    securityImpact: "CVE-2024-1234: XSS vulnerability in JSX rendering",
                    migrationComplexity: .complex,
                    recommendedAction: "Update immediately. Test all JSX components. Review breaking changes in React 19 migration guide."
                )
            ],
            safeUpdates: [
                AIDependencyInsight(
                    dependencyName: "lodash",
                    currentVersion: "4.17.15",
                    latestVersion: "4.17.21",
                    riskLevel: .recommended,
                    reason: "Patch release with bug fixes. No breaking changes.",
                    breakingChanges: false,
                    migrationComplexity: .simple,
                    recommendedAction: "Safe to batch update. No code changes required."
                ),
                AIDependencyInsight(
                    dependencyName: "express",
                    currentVersion: "4.18.0",
                    latestVersion: "4.19.0",
                    riskLevel: .recommended,
                    reason: "Minor version bump with security patches and performance improvements.",
                    breakingChanges: false,
                    migrationComplexity: .simple,
                    recommendedAction: "Safe to update. Run tests after update."
                )
            ],
            reviewRecommended: [
                AIDependencyInsight(
                    dependencyName: "webpack",
                    currentVersion: "5.75.0",
                    latestVersion: "5.90.0",
                    riskLevel: .important,
                    reason: "Major configuration changes. Some deprecated options removed.",
                    breakingChanges: true,
                    migrationComplexity: .moderate,
                    recommendedAction: "Review webpack config before updating. Check deprecated options."
                )
            ],
            actionPlan: [
                "1. Update react immediately (critical security)",
                "2. Review and test webpack config changes",
                "3. Batch update lodash and express (safe updates)",
                "4. Run full test suite before deploying"
            ],
            estimatedTime: "4-6 hours including testing",
            overallRiskScore: 65
        )
    }
}
