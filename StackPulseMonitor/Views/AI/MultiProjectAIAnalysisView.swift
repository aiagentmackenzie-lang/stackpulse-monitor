import SwiftUI

@available(iOS 16.0, *)
struct MultiProjectAIAnalysisView: View {
    let viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAnalyzing = false
    @State private var report: MultiProjectAIReport?
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isAnalyzing {
                    AnalyzingProgressView()
                } else if let report = report {
                    MultiProjectAIReportView(report: report)
                } else if let error = error {
                    ErrorView(message: error)
                } else {
                    ReadyView(onAnalyze: {
                        Task { await analyze() }
                    })
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func analyze() async {
        isAnalyzing = true
        
        let projectsWithIssues = viewModel.projects.filter { $0.outdatedCount > 0 }
        
        guard !projectsWithIssues.isEmpty else {
            error = "No outdated dependencies found"
            isAnalyzing = false
            return
        }
        
        var projectReports: [ProjectAIReport] = []
        
        for project in projectsWithIssues {
            do {
                if let projectReport = try await viewModel.generateAIReport(for: project.id) {
                    projectReports.append(projectReport)
                }
            } catch {
                print("Failed to analyze \(project.name): \(error)")
            }
        }
        
        let totalCritical = projectReports.reduce(0) { $0 + $1.criticalUpdates.count }
        let totalSafe = projectReports.reduce(0) { $0 + $1.safeUpdates.count }
        let totalReview = projectReports.reduce(0) { $0 + $1.reviewRecommended.count }
        
        report = MultiProjectAIReport(
            summary: "Analyzed \(projectsWithIssues.count) projects with \(totalCritical + totalSafe + totalReview) outdated dependencies",
            totalOutdated: totalCritical + totalSafe + totalReview,
            criticalCount: totalCritical,
            safeCount: totalSafe,
            reviewCount: totalReview,
            crossProjectPlan: generateCrossProjectPlan(from: projectReports),
            projects: projectReports
        )
        
        isAnalyzing = false
    }
    
    private func generateCrossProjectPlan(from reports: [ProjectAIReport]) -> [String] {
        var plan: [String] = []
        
        let allCritical = reports.flatMap { $0.criticalUpdates }
        if !allCritical.isEmpty {
            plan.append("Address \(allCritical.count) critical security updates immediately")
        }
        
        let allSafe = reports.flatMap { $0.safeUpdates }
        if !allSafe.isEmpty {
            plan.append("Batch update \(allSafe.count) low-risk dependencies")
        }
        
        let allReview = reports.flatMap { $0.reviewRecommended }
        if !allReview.isEmpty {
            plan.append("Review \(allReview.count) updates with breaking changes")
        }
        
        plan.append("Run full test suite after all updates")
        
        return plan
    }
}

struct AnalyzingProgressView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your stack...")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("This may take a minute")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }
}

struct ReadyView: View {
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            Text("Ready to Analyze")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            
            Text("AI will analyze all your projects and provide a prioritized action plan")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onAnalyze) {
                Label("Start Analysis", systemImage: "wand.and.stars")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}
