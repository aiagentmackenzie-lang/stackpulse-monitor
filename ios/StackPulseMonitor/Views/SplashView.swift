import SwiftUI

struct SplashView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var waveOffset: CGFloat = -200
    @State private var statusText = "Initializing..."
    @State private var loadingProgress: CGFloat = 0

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(spacing: 8) {
                    Text("STACKPULSE")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(2)

                    Text("Your stack. Your signal.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(Theme.muted.opacity(0.3))
                            .frame(height: 2)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(Theme.accent)
                                    .frame(width: geo.size.width * loadingProgress, height: 2)
                            }
                    }
                    .frame(height: 2)
                    .padding(.horizontal, 60)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.4
            pulseOpacity = 0.0
        }

        withAnimation(.easeInOut(duration: 0.8)) {
            loadingProgress = 0.3
        }

        Task {
            try? await Task.sleep(for: .seconds(0.8))
            statusText = "Loading your stack..."
            withAnimation(.easeInOut(duration: 0.8)) {
                loadingProgress = 0.65
            }

            try? await Task.sleep(for: .seconds(0.8))
            statusText = "Checking for alerts..."
            withAnimation(.easeInOut(duration: 0.6)) {
                loadingProgress = 1.0
            }

            try? await Task.sleep(for: .seconds(0.6))
            onComplete()
        }
    }
}
