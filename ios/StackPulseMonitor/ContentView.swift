import SwiftUI

enum AppPhase {
    case splash
    case onboarding
    case apiKeySetup
    case stackSetup
    case main
}

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    @State private var phase: AppPhase = .splash

    var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView {
                    advanceFromSplash()
                }

            case .onboarding:
                OnboardingView(viewModel: viewModel) {
                    viewModel.completeOnboarding()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        phase = .apiKeySetup
                    }
                }
                .transition(.move(edge: .trailing))

            case .apiKeySetup:
                APIKeySetupView(viewModel: viewModel) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        phase = .stackSetup
                    }
                }
                .transition(.move(edge: .trailing))

            case .stackSetup:
                StackSetupView(viewModel: viewModel) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        phase = .main
                    }
                    Task {
                        // Sync both legacy stack and new projects
                        await viewModel.syncStack()
                        await viewModel.checkAllProjectsForAlerts()
                    }
                }
                .transition(.move(edge: .trailing))

            case .main:
                MainTabView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
        .preferredColorScheme(.dark)
    }

    private func advanceFromSplash() {
        viewModel.loadFromStorage()

        if viewModel.hasCompletedSetup {
            withAnimation(.easeInOut(duration: 0.4)) {
                phase = .main
            }
        } else if viewModel.hasOnboarded {
            withAnimation(.easeInOut(duration: 0.4)) {
                phase = .stackSetup
            }
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                phase = .onboarding
            }
        }
    }
}
