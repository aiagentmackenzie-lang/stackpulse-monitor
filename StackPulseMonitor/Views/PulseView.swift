import SwiftUI

/// Project Dashboard showing health cards for all projects
struct PulseView: View {
    @Bindable var viewModel: AppViewModel
    @State private var selectedProject: Project?
    @State private var isCheckingVersions = false
    @State private var checkProgress = ""
    @State private var showMultiProjectAnalysis = false
    @State private var showProjectPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header with overall stats
                    headerSection
                    
                    // AI Banner (always visible)
                    AIAnalysisBanner(onAnalyze: {
                        showProjectPicker = true
                    })
                    
                    // Projects list
                    if viewModel.projects.isEmpty {
                        emptyState
                    } else {
                        projectsSection
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Pulse")
            .sheet(item: $selectedProject) { project in
                NavigationStack {
                    ProjectDetailView(projectId: project.id, viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Done") {
                                    selectedProject = nil
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showMultiProjectAnalysis) {
                MultiProjectAIAnalysisView(viewModel: viewModel)
            }
            .sheet(isPresented: $showProjectPicker) {
                AIProjectPickerSheet(viewModel: viewModel) { selectedProjects in
                    // Store selection and trigger multi-project analysis
                    // (Works for both single and multiple projects)
                    showMultiProjectAnalysis = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Overall stats
            HStack(spacing: 16) {
                PulseStatCard(
                    value: viewModel.projects.count,
                    label: "Projects",
                    icon: "folder.fill",
                    color: Theme.accent
                )
                
                PulseStatCard(
                    value: totalDepCount,
                    label: "Dependencies",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                PulseStatCard(
                    value: totalOutdatedCount,
                    label: "Outdated",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Last updated
            if let lastUpdate = lastUpdateTime {
                HStack {
                    Spacer()
                    Label("Updated \(timeAgo(from: lastUpdate))", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Projects Section
    
    private var projectsSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.projects) { project in
                PulseProjectCard(project: project) {
                    selectedProject = project
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "pulse")
                .font(.system(size: 60))
                .foregroundStyle(Theme.muted)
            
            VStack(spacing: 8) {
                Text("No Projects")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("Add projects from GitHub or manually to start monitoring")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                NotificationCenter.default.post(name: .switchToProjectsTab, object: nil)
            } label: {
                Label("Add Project", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .clipShape(.rect(cornerRadius: 10))
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helpers
    
    private var totalDepCount: Int {
        viewModel.projects.reduce(0) { $0 + $1.dependencyCount }
    }
    
    private var totalOutdatedCount: Int {
        viewModel.projects.reduce(0) { $0 + $1.outdatedCount }
    }
    
    private var hasOutdatedDependencies: Bool {
        totalOutdatedCount > 0
    }
    
    private var lastUpdateTime: Date? {
        // Get the most recent lastChecked from any dependency across all projects
        let allTimes = viewModel.projects.flatMap { project in
            project.dependencies.compactMap { $0.lastChecked }
        }
        return allTimes.max()
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - AI Analysis Banner

struct AIAnalysisBanner: View {
    let onAnalyze: () -> Void
    
    var body: some View {
        Button(action: onAnalyze) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get AI Analysis")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("See recommendations for outdated dependencies")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.muted)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

// MARK: - Stat Card

struct PulseStatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text("\(value)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: 0x1A1A1A))
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Pulse View - With Projects") {
    PulseView(viewModel: AppViewModel()).preferredColorScheme(.dark)
}
