import SwiftUI

/// List view showing all projects with AI thread summaries
struct AIThreadListView: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProject: Project?
    @State private var searchText = ""
    @State private var showNewChatSheet = false
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return viewModel.projects
        }
        return viewModel.projects.filter { project in
            project.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Empty state
                        if viewModel.projects.isEmpty {
                            EmptyStateView()
                        } else {
                            // Search bar
                            SearchBar(text: $searchText)
                                .padding(.horizontal, 16)
                            
                            // Project list
                            ForEach(filteredProjects) { project in
                                ThreadListRow(project: project, viewModel: viewModel)
                                    .onTapGesture {
                                        selectedProject = project
                                    }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
                
                // Floating action button for new chat
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showNewChatSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.purple)
                                .clipShape(Circle())
                                .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedProject) { project in
                AIChatView(project: project, viewModel: viewModel)
            }
            .sheet(isPresented: $showNewChatSheet) {
                NewChatProjectPicker(viewModel: viewModel) { project in
                    selectedProject = project
                }
            }
        }
    }
}

// MARK: - Thread List Row

struct ThreadListRow: View {
    let project: Project
    let viewModel: AppViewModel
    
    var summary: AIThreadSummary? {
        project.threadSummary
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Project icon
            ZStack {
                Circle()
                    .fill(projectGradient)
                    .frame(width: 48, height: 48)
                
                Text(project.name.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            // Project info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    if summary?.hasNewMessages ?? false {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(summary?.lastActivity ?? "")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
                
                // Latest message preview
                Text(summary?.preview ?? "Start a new conversation")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                
                // Stats
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.caption2)
                        Text("\(project.dependencyCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.textSecondary)
                    
                    if project.outdatedCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("\(project.outdatedCount)")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.muted)
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
    
    private var projectGradient: LinearGradient {
        let hash = project.name.hashValue
        let colors: [Color] = [.purple, .blue, .pink, .orange, .green, .cyan]
        let color1 = colors[abs(hash) % colors.count]
        let color2 = colors[(abs(hash) + 1) % colors.count]
        
        return LinearGradient(
            colors: [color1.opacity(0.8), color2.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.muted)
            
            TextField("Search projects...", text: $text)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .padding(12)
        .background(Color(hex: 0x2A2A2A))
        .clipShape(.rect(cornerRadius: 10))
    }
}

// MARK: - New Chat Project Picker

struct NewChatProjectPicker: View {
    let viewModel: AppViewModel
    let onSelect: (Project) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text("Select a project to chat with")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 20)
                    
                    ForEach(viewModel.projects) { project in
                        Button(action: {
                            onSelect(project)
                            dismiss()
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text(project.name.prefix(1).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.purple)
                                }
                                
                                Text(project.name)
                                    .font(.body)
                                    .foregroundStyle(Theme.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.muted)
                            }
                            .padding(12)
                            .background(Color(hex: 0x1A1A1A))
                            .clipShape(.rect(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.purple.opacity(0.5))
            
            Text("No Projects Yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            
            Text("Add a project first to start chatting with AI about your dependencies.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                NotificationCenter.default.post(name: .switchToProjectsTab, object: nil)
            } label: {
                Label("Go to Projects", systemImage: "folder.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.top, 8)
        }
        .padding(.top, 80)
    }
}

// MARK: - Preview

#Preview("Thread List") {
    let vm = AppViewModel()
    vm.projects = [
        Project(
            name: "MyApp",
            source: .github,
            dependencies: [
                Dependency(name: "react", type: .npm, category: .frontend, currentVersion: "18.2.0", isOutdated: true)
            ]
        ),
        Project(
            name: "Backend API",
            source: .github,
            dependencies: [
                Dependency(name: "express", type: .npm, category: .backend, currentVersion: "4.18.0", isOutdated: false)
            ]
        )
    ]
    
    return AIThreadListView(viewModel: vm)
}
