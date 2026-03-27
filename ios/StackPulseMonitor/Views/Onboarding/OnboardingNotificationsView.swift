import SwiftUI

/// Onboarding step for requesting notification permissions
struct OnboardingNotificationsView: View {
    @Bindable var viewModel: AppViewModel
    @State private var isRequesting = false
    @State private var permissionStatus: Bool?
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.purple)
            }
            .padding(.bottom, 32)
            
            // Title
            Text("Stay Informed")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            
            // Description
            Text("Get notified when StackPulse finds vulnerabilities, important updates, or end-of-life warnings for your dependencies.")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            
            // Feature list
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "shield.exclamationmark.fill", color: .red, text: "Critical security alerts")
                featureRow(icon: "arrow.up.circle.fill", color: .blue, text: "Version update notifications")
                featureRow(icon: "clock.badge.exclamationmark.fill", color: .orange, text: "End-of-life warnings")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 16) {
                Button {
                    requestPermission()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "bell.fill")
                            Text("Enable Notifications")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.purple)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .disabled(isRequesting)
                
                Button {
                    onSkip()
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            checkExistingPermission()
        }
    }
    
    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
        }
    }
    
    private func requestPermission() {
        isRequesting = true
        
        Task {
            let granted = await viewModel.requestNotificationPermissions()
            
            await MainActor.run {
                isRequesting = false
                permissionStatus = granted
                
                // Small delay before continuing so user sees the result
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onContinue()
                }
            }
        }
    }
    
    private func checkExistingPermission() {
        Task {
            await viewModel.checkNotificationPermissions()
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingNotificationsView(
        viewModel: AppViewModel(),
        onContinue: {},
        onSkip: {}
    )
}
