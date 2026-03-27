import SwiftUI

@available(iOS 16.0, *)
struct MultiProjectAIReportView: View {
    let report: MultiProjectAIReport
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SummaryCard(report: report)
                
                ActionPlanCard(plan: report.crossProjectPlan)
                
                ProjectDetailsSection(projects: report.projects)
            }
            .padding(.vertical, 20)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

struct SummaryCard: View {
    let report: MultiProjectAIReport
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stack Overview")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text(report.summary)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatPill(value: report.criticalCount, label: "Critical", color: .red)
                StatPill(value: report.safeCount, label: "Safe", color: .green)
                StatPill(value: report.reviewCount, label: "Review", color: .orange)
            }
        }
        .padding(16)
        .background(Color(hex: 0x1A1A1A))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct ActionPlanCard: View {
    let plan: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.purple)
                Text("Cross-Project Action Plan")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(plan.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                            .frame(width: 24, height: 24)
                            .background(Color.purple.opacity(0.2))
                            .clipShape(Circle())
                        
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: 0x1A1A1A))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct ProjectDetailsSection: View {
    let projects: [ProjectAIReport]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Details")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 16)
            
            ForEach(projects) { project in
                ProjectSummaryCard(report: project)
            }
        }
    }
}

struct ProjectSummaryCard: View {
    let report: ProjectAIReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(Theme.accent)
                
                Text("Project \(report.projectId.uuidString.prefix(8))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if report.hasCritical {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    if report.hasSafe {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Text(report.summary)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color(hex: 0x1A1A1A))
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct StatPill: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))
    }
}

// MARK: - Model

struct MultiProjectAIReport: Identifiable {
    let id = UUID()
    let summary: String
    let totalOutdated: Int
    let criticalCount: Int
    let safeCount: Int
    let reviewCount: Int
    let crossProjectPlan: [String]
    let projects: [ProjectAIReport]
}
