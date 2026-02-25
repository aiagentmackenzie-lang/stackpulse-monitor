import SwiftUI

struct APIKeySetupView: View {
    let viewModel: AppViewModel
    let onComplete: () -> Void

    @State private var apiKey = ""
    @State private var isKeyVisible = false
    @State private var isTesting = false
    @State private var testResult: TestResult?

    private enum TestResult {
        case success
        case failure
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.accent)

                        Text("Power Up with AI")
                            .font(.title.bold())
                            .foregroundStyle(Theme.textPrimary)

                        Text("STACKPULSE uses GPT-4o to summarize updates in plain English")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to get your key:")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        VStack(alignment: .leading, spacing: 8) {
                            instructionRow("1", "Go to platform.openai.com")
                            instructionRow("2", "Create an account or log in")
                            instructionRow("3", "Click API Keys → Create new key")
                            instructionRow("4", "Paste it below")
                        }
                    }
                    .padding(16)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)

                        HStack(spacing: 8) {
                            Group {
                                if isKeyVisible {
                                    TextField("sk-proj-...", text: $apiKey)
                                } else {
                                    SecureField("sk-proj-...", text: $apiKey)
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)

                            Button {
                                isKeyVisible.toggle()
                            } label: {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.border, lineWidth: 1)
                        )

                        Text("Stored locally on your device only. Never sent to our servers.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 4)

                    if let result = testResult {
                        HStack(spacing: 8) {
                            Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(result == .success ? "Key valid! AI features enabled" : "Invalid key — check and try again")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(result == .success ? Theme.success : Theme.danger)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background((result == .success ? Theme.success : Theme.danger).opacity(0.12))
                        .clipShape(.rect(cornerRadius: 10))
                    }

                    Button {
                        testAndSave()
                    } label: {
                        HStack(spacing: 8) {
                            if isTesting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isTesting ? "TESTING..." : "TEST & SAVE KEY")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(apiKey.isEmpty ? Theme.muted : Theme.accent)
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(apiKey.isEmpty || isTesting)

                    Button {
                        onComplete()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(Theme.accent)
                .frame(width: 20, height: 20)
                .background(Theme.accent.opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func testAndSave() {
        isTesting = true
        testResult = nil
        Task {
            do {
                let valid = try await NetworkService.shared.testOpenAIKey(apiKey)
                if valid {
                    testResult = .success
                    viewModel.saveOpenAIKey(apiKey)
                    try? await Task.sleep(for: .seconds(1.0))
                    onComplete()
                } else {
                    testResult = .failure
                }
            } catch {
                testResult = .failure
            }
            isTesting = false
        }
    }
}
