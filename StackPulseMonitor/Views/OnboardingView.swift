import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showNotificationsStep = false
    let viewModel: AppViewModel
    let onComplete: () -> Void

    private let slides: [(icon: String, title: String, body: String)] = [
        (
            "shippingbox.fill",
            "Watch Only Your Stack",
            "Stop reading generic tech news. STACKPULSE monitors only the tools YOU use — React, Postgres, NestJS, whatever you actually ship with."
        ),
        (
            "shield.checkerboard",
            "CVEs Before They Bite You",
            "Get alerted to critical vulnerabilities in your dependencies before your production app is exposed. Real data from OSV.dev."
        ),
        (
            "brain.head.profile.fill",
            "AI Tells You What Matters",
            "Every update gets an AI summary: What changed, is it urgent, and exactly what to do next. No release note reading required."
        )
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if showNotificationsStep {
                // Notifications step
                OnboardingNotificationsView(
                    viewModel: viewModel,
                    onContinue: {
                        onComplete()
                    },
                    onSkip: {
                        onComplete()
                    }
                )
            } else {
                // Main onboarding slides
                mainOnboardingContent
            }
        }
    }

    private var mainOnboardingContent: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                    slideView(icon: slide.icon, title: slide.title, body: slide.body)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Theme.accent : Theme.muted)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }

                if currentPage == 2 {
                    Button {
                        withAnimation {
                            showNotificationsStep = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("GET STARTED")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 40)
        }
    }

    private func slideView(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.bounce, value: currentPage)
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(body)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}
