import SwiftUI

struct StackView: View {
    let viewModel: AppViewModel
    @State private var showAddSheet = false
    @State private var selectedTech: Technology?
    @State private var expandedCategories: Set<TechCategory> = Set(TechCategory.allCases)

    private var groupedItems: [(TechCategory, [Technology])] {
        let grouped = Dictionary(grouping: viewModel.stackItems) { $0.category }
        return TechCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.stackItems.isEmpty {
                    ContentUnavailableView("No Technologies", systemImage: "shippingbox", description: Text("Add technologies to monitor your stack"))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(groupedItems, id: \.0) { category, items in
                            categorySection(category: category, items: items)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
                }
            }
            .background(Theme.background)
            .navigationTitle("My Stack")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.accent)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(viewModel.stackItems.count) items")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .sheet(isPresented: $showAddSheet) {
                AddTechnologySheet(viewModel: viewModel)
            }
            .sheet(item: $selectedTech) { tech in
                TechnologyDetailView(viewModel: viewModel, technology: tech)
            }
        }
    }

    private func categorySection(category: TechCategory, items: [Technology]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    Text("\(category.rawValue) (\(items.count))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 4)

            if expandedCategories.contains(category) {
                ForEach(items) { tech in
                    Button {
                        selectedTech = tech
                    } label: {
                        stackItemRow(tech)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func stackItemRow(_ tech: Technology) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tech.status.color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: tech.status.icon)
                        .font(.caption)
                        .foregroundStyle(tech.status.color)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(tech.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(tech.currentVersion.isEmpty ? "No version set" : "v\(tech.currentVersion)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(tech.status.label)
                .font(.caption2.bold())
                .foregroundStyle(tech.status.color)
        }
        .padding(.vertical, 4)
    }
}

struct AddTechnologySheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AppViewModel
    
    // GitHub OAuth
    @StateObject private var authService = GitHubAuthService.shared
    @State private var showRepoList = false

    @State private var searchText = ""
    @State private var searchResults: [NPMSearchPackage] = []
    @State private var isSearching = false
    @State private var manualName = ""
    @State private var manualType: TechType = .npm
    @State private var manualCategory: TechCategory = .other
    @State private var manualVersion = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedRepos: [GitHubRepository] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search NPM")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.textSecondary)
                            TextField("Search packages...", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .padding(12)
                        .background(Color(hex: 0x1A1A1A))
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.border, lineWidth: 1)
                        )

                        if isSearching {
                            HStack {
                                ProgressView().tint(Theme.accent)
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(.top, 4)
                        }

                        ForEach(searchResults, id: \.name) { pkg in
                            Button {
                                addFromSearch(pkg)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pkg.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Theme.textPrimary)
                                        if let desc = pkg.description {
                                            Text(desc)
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Text("v\(pkg.version)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.muted)
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Theme.accent)
                                }
                                .padding(10)
                                .background(Theme.cardBackground)
                                .clipShape(.rect(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // GitHub Import Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Import from GitHub")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        
                        if authService.isAuthenticated {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Connected")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text(authService.username ?? "")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                }
                                
                                Button {
                                    showRepoList = true
                                } label: {
                                    HStack {
                                        Image(systemName: "minus.circle")
                                        Text("Add from GitHub")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Theme.accent)
                                    .clipShape(.rect(cornerRadius: 8))
                                }
                            }
                        } else {
                            GitHubAuthButton {
                                showRepoList = true
                            }
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    .sheet(isPresented: $showRepoList) {
                        GitHubRepoListView(onReposSelected: { repos in
                            selectedRepos = repos
                            showRepoList = false
                            dismiss()
                        })
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manual Entry")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        TextField("Technology name", text: $manualName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(Color(hex: 0x1A1A1A))
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.border, lineWidth: 1)
                            )

                        TextField("Version (optional)", text: $manualVersion)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(Theme.textPrimary)
                            .padding(12)
                            .background(Color(hex: 0x1A1A1A))
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.border, lineWidth: 1)
                            )

                        HStack(spacing: 8) {
                            Picker("Type", selection: $manualType) {
                                ForEach(TechType.allCases, id: \.self) { type in
                                    Text(type.rawValue.uppercased()).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.accent)

                            Picker("Category", selection: $manualCategory) {
                                ForEach(TechCategory.allCases, id: \.self) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.accent)
                        }

                        Button {
                            addManual()
                        } label: {
                            Text("ADD TO STACK")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(manualName.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.muted : Theme.accent)
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        .disabled(manualName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(16)
                    .cardStyle()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .navigationTitle("Add Technology")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                guard newValue.count >= 2 else {
                    searchResults = []
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    isSearching = true
                    do {
                        let results = try await NetworkService.shared.searchNPM(newValue)
                        if !Task.isCancelled {
                            searchResults = results
                        }
                    } catch {
                        if !Task.isCancelled {
                            searchResults = []
                        }
                    }
                    isSearching = false
                }
            }
        }
    }

    private func addFromSearch(_ pkg: NPMSearchPackage) {
        let tech = Technology(
            name: pkg.name,
            type: .npm,
            identifier: pkg.name,
            category: .other,
            latestVersion: pkg.version
        )
        viewModel.addTechnology(tech)
        dismiss()
    }

    private func addManual() {
        let name = manualName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tech = Technology(
            name: name,
            type: manualType,
            identifier: name.lowercased(),
            category: manualCategory,
            currentVersion: manualVersion
        )
        viewModel.addTechnology(tech)
        dismiss()
    }
}
