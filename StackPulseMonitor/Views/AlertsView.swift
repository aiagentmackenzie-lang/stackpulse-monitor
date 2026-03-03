import SwiftUI

struct AlertsView: View {
    let viewModel: AppViewModel
    @State private var selectedFilter: AlertFilter = .all
    @State private var selectedTech: Technology?
    @State private var selectedProjectId: UUID?

    private enum AlertFilter: String, CaseIterable {
        case all = "ALL"
        case critical = "CRITICAL"
        case updates = "UPDATES"
        case eol = "EOL"
        case breaking = "BREAKING"
    }

    private var filteredAlerts: [TechAlert] {
        let active = viewModel.activeAlerts
        switch selectedFilter {
        case .all: return active
        case .critical: return active.filter { $0.type == .critical }
        case .updates: return active.filter { $0.type == .update }
        case .eol: return active.filter { $0.type == .eol }
        case .breaking: return active.filter { $0.type == .breaking }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips
                    .padding(.vertical, 8)

                ScrollView {
                    if filteredAlerts.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAlerts) { alert in
                                alertCard(alert)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Alerts")
            .toolbarBackground(Theme.background, for: .navigationBar)
            .onAppear {
                // Mark all alerts as read and clear ALL notifications
                viewModel.markAllAlertsAsRead()
                
                // Also directly clear all notifications as a safety net
                viewModel.clearAllNotifications()
            }
            .navigationDestination(item: $selectedProjectId) { projectId in
                ProjectDetailView(projectId: projectId, viewModel: viewModel)
            }
            .sheet(item: $selectedTech) { tech in
                TechnologyDetailView(viewModel: viewModel, technology: tech)
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AlertFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(selectedFilter == filter ? .white : Theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedFilter == filter ? Theme.accent : Theme.cardBackground)
                            .clipShape(.capsule)
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? Theme.accent : Theme.border, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .contentMargins(.horizontal, 0)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.success.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.success)
                    .symbolEffect(.pulse, options: .repeating)
            }

            Text("All Clear")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("No alerts right now.\nYour stack is healthy.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }

    private func alertCard(_ alert: TechAlert) -> some View {
        Button {
            // Mark as read when tapped
            viewModel.markAlertAsRead(alert.id)
            
            // Try to find project first (new model)
            if let project = viewModel.findProject(forTechId: alert.techId) {
                selectedProjectId = project.id
            } else if let tech = viewModel.stackItems.first(where: { $0.id == alert.techId }) {
                // Legacy fallback
                selectedTech = tech
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: alert.type.icon)
                            .font(.caption)
                            .foregroundStyle(alert.type.color)
                        Text(alert.type.label)
                            .font(.caption.bold())
                            .foregroundStyle(alert.type.color)
                    }
                    Spacer()
                    Text(alert.techName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.muted.opacity(0.3))
                        .clipShape(.capsule)
                }

                Text(alert.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(alert.message)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(alert.createdAt.relativeString)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("VIEW DETAILS")
                            .font(.caption2.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(alert.type.color)
                }
            }
            .padding(14)
            .background(alert.type.color.opacity(0.04))
            .clipShape(.rect(cornerRadius: Theme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(alert.type.color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: alert.type.color.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.dismissAlert(alert)
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
        }
        .contextMenu {
            Button {
                viewModel.dismissAlert(alert)
            } label: {
                Label("Dismiss", systemImage: "xmark.circle")
            }
            Button {
                viewModel.snoozeAlert(alert, days: 7)
            } label: {
                Label("Snooze 7 Days", systemImage: "moon.zzz")
            }
        }
    }
}
