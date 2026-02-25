import SwiftUI

struct PulseView: View {
    let viewModel: AppViewModel
    @State private var selectedTech: Technology?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    healthScoreCard

                    if viewModel.criticalCount > 0 {
                        criticalBanner
                    }

                    if viewModel.openAIKey.isEmpty {
                        aiKeyBanner
                    }

                    ForEach(viewModel.stackItems) { tech in
                        Button {
                            selectedTech = tech
                        } label: {
                            techStatusCard(tech)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .refreshable {
                await viewModel.syncStack()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(Theme.accent)
                        Text("STACKPULSE")
                            .font(.headline.bold())
                            .foregroundStyle(Theme.textPrimary)
                            .tracking(1)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.syncStack() }
                    } label: {
                        VStack(alignment: .trailing, spacing: 2) {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundStyle(Theme.accent)
                                .symbolEffect(.rotate, isActive: viewModel.isSyncing)
                        }
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .sheet(item: $selectedTech) { tech in
                TechnologyDetailView(viewModel: viewModel, technology: tech)
            }
            .overlay {
                if viewModel.isSyncing {
                    VStack {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(Theme.accent)
                            Text(viewModel.syncProgress)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                        Spacer()
                    }
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var healthScoreCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Theme.muted.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.healthScore) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(viewModel.healthScore)")
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundStyle(scoreColor)
                        Text("/100")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Stack Health")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)

                    statRow(icon: "checkmark.circle.fill", color: Theme.success, label: "Up to date", count: viewModel.upToDateCount)
                    statRow(icon: "exclamationmark.triangle.fill", color: Theme.warning, label: "Updates", count: viewModel.updateCount)
                    statRow(icon: "shield.exclamationmark.fill", color: Theme.danger, label: "Critical", count: viewModel.criticalCount)
                }
            }

            if let lastSync = viewModel.lastSyncTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Synced \(lastSync.relativeString)")
                        .font(.caption)
                }
                .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(20)
        .cardStyle()
    }

    private var scoreColor: Color {
        if viewModel.healthScore >= 80 { return Theme.success }
        if viewModel.healthScore >= 60 { return Theme.warning }
        return Theme.danger
    }

    private func statRow(icon: String, color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text("\(label): \(count)")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var criticalBanner: some View {
        Button {
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(Theme.danger)
                Text("\(viewModel.criticalCount) CRITICAL VULNERABILITIES DETECTED")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.danger)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.danger.opacity(0.7))
            }
            .padding(14)
            .background(Theme.danger.opacity(0.1))
            .clipShape(.rect(cornerRadius: Theme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Theme.danger.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var aiKeyBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile.fill")
                .foregroundStyle(Theme.accent)
            Text("Add OpenAI key in Settings for AI summaries")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.08))
        .clipShape(.rect(cornerRadius: 10))
    }

    private func techStatusCard(_ tech: Technology) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tech.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: tech.status.icon)
                        .font(.caption2)
                    Text(tech.status.label)
                        .font(.caption.bold())
                }
                .foregroundStyle(tech.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tech.status.color.opacity(0.12))
                .clipShape(.capsule)
            }

            if !tech.latestVersion.isEmpty {
                HStack(spacing: 4) {
                    Text("v\(tech.latestVersion)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                    if !tech.currentVersion.isEmpty {
                        Text("(your: \(tech.currentVersion))")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            if let summary = tech.aiSummary, !summary.isEmpty {
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 0.5)

                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            if let lastChecked = tech.lastChecked {
                HStack {
                    Spacer()
                    Text("Last checked: \(lastChecked.relativeString)")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}
