import SwiftUI

/// Sheet for selecting which projects to analyze with AI
struct AIProjectPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AppViewModel
    let onAnalyze: ([Project]) -> Void
    
    @State private var selectedProjectIds: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(.purple)
                        
                        Text("Select Projects")
                            .font(.title2.weight(.bold))
                        
                        Text("Choose which projects to analyze with AI")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Select All Toggle
                    Toggle("Analyze All Projects", isOn: isAllSelected)
                        .padding(.horizontal, 16)
                        .tint(.purple)
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Project List
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.projects) { project in
                            ProjectSelectionRow(
                                project: project,
                                isSelected: isSelected(project)
                            ) {
                                toggleSelection(project)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Analyze") {
                        let selected = viewModel.projects.filter { 
                            selectedProjectIds.contains($0.id) 
                        }
                        dismiss()
                        onAnalyze(selected)
                    }
                    .disabled(selectedProjectIds.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var isAllSelected: Binding<Bool> {
        Binding(
            get: { selectedProjectIds.count == viewModel.projects.count },
            set: { selectAll in
                if selectAll {
                    selectedProjectIds = Set(viewModel.projects.map(\.id))
                } else {
                    selectedProjectIds.removeAll()
                }
            }
        )
    }
    
    private func isSelected(_ project: Project) -> Bool {
        selectedProjectIds.contains(project.id)
    }
    
    private func toggleSelection(_ project: Project) {
        if isSelected(project) {
            selectedProjectIds.remove(project.id)
        } else {
            selectedProjectIds.insert(project.id)
        }
    }
}

// MARK: - Project Selection Row

struct ProjectSelectionRow: View {
    let project: Project
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .purple : .gray)
                
                // Project info
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("\(project.outdatedCount) outdated")
                        .font(.caption)
                        .foregroundStyle(project.outdatedCount > 0 ? .orange : .secondary)
                }
                
                Spacer()
                
                // Dependency count
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .font(.caption)
                    Text("\(project.dependencyCount)")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(12)
            .background(Color(hex: 0x1A1A1A))
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple.opacity(0.5) : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Project Picker") {
    let vm = AppViewModel()
    vm.projects = [
        Project(name: "MyApp", source: .github, dependencies: [
            Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0", isOutdated: true)
        ]),
        Project(name: "Backend API", source: .github, dependencies: [
            Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0", isOutdated: false)
        ])
    ]
    
    return AIProjectPickerSheet(viewModel: vm) { projects in
        print("Selected: \(projects.map(\.name))")
    }
}
