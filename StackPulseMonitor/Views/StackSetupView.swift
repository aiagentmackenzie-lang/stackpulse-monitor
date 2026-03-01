import SwiftUI

struct StackSetupView: View {
    let viewModel: AppViewModel
    let onComplete: () -> Void
    
    // GitHub OAuth
    @StateObject private var authService = GitHubAuthService.shared
    @State private var showRepoList = false


    @State private var selectedPresets: Set<String> = []
    @State private var customName = ""
    @State private var customType: TechType = .npm
    @State private var expandedCategories: Set<TechCategory> = Set(TechCategory.allCases)

    private let categories: [TechCategory] = [.frontend, .backend, .database, .devops, .language]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Build Your Stack")
                        .font(.title.bold())
                        .foregroundStyle(Theme.textPrimary)

                    Text("Add the technologies you actually use")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        // GitHub Import Section
                        VStack(spacing: 16) {
                            if authService.isAuthenticated {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Connected to GitHub")
                                                .font(.headline)
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

                        ForEach(categories, id: \.self) { category in
                            categorySection(category)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Technology")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            HStack(spacing: 8) {
                                TextField("Package name...", text: $customName)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.body)
                                    .foregroundStyle(Theme.textPrimary)
                                    .padding(10)
                                    .background(Theme.cardBackground)
                                    .clipShape(.rect(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.border, lineWidth: 1)
                                    )

                                Button {
                                    addCustomTech()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Theme.accent)
                                        .clipShape(.rect(cornerRadius: 8))
                                }
                                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(16)
                        .cardStyle()

                        if !viewModel.stackItems.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Stack (\(viewModel.stackItems.count))")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)

                                ForEach(viewModel.stackItems) { tech in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(tech.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Theme.textPrimary)
                                            Text(tech.category.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                        Spacer()
                                        Button {
                                            viewModel.removeTechnology(tech)
                                            selectedPresets.remove(tech.name)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                    .padding(10)
                                    .background(Theme.accent.opacity(0.08))
                                    .clipShape(.rect(cornerRadius: 8))
                                }
                            }
                            .padding(16)
                            .cardStyle()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            VStack {
                Spacer()
                Button {
                    viewModel.completeSetup()
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Text("FINISH SETUP")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.stackItems.isEmpty ? Theme.muted : Theme.accent)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .disabled(viewModel.stackItems.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [Theme.background.opacity(0), Theme.background, Theme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .sheet(isPresented: $showRepoList) {
            GitHubRepoListView(onReposSelected: { repos in
                showRepoList = false
            })
        }
    }

    private func categorySection(_ category: TechCategory) -> some View {
        let presets = PresetTech.forCategory(category)
        return VStack(alignment: .leading, spacing: 10) {
            Text(category.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(presets, id: \.name) { preset in
                    let isSelected = selectedPresets.contains(preset.name)
                    Button {
                        togglePreset(preset)
                    } label: {
                        Text(preset.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Theme.accent : Theme.cardBackground)
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func togglePreset(_ preset: PresetTech) {
        if selectedPresets.contains(preset.name) {
            selectedPresets.remove(preset.name)
            viewModel.stackItems.removeAll { $0.name == preset.name }
        } else {
            selectedPresets.insert(preset.name)
            let tech = Technology(
                name: preset.name,
                type: preset.type,
                identifier: preset.identifier,
                category: preset.category
            )
            viewModel.addTechnology(tech)
        }
    }

    private func addCustomTech() {
        let name = customName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tech = Technology(
            name: name,
            type: customType,
            identifier: name.lowercased(),
            category: .other
        )
        viewModel.addTechnology(tech)
        customName = ""
    }
}
