import SwiftUI

/// Horizontal scrollable quick action prompts for AI chat
struct QuickPromptsView: View {
    let prompts: [QuickPrompt]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(prompts) { prompt in
                    PromptChip(prompt: prompt) {
                        onSelect(prompt.text)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

/// Individual prompt chip
struct PromptChip: View {
    let prompt: QuickPrompt
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(prompt.icon)
                    .font(.system(size: 14))
                Text(prompt.title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.purple)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.15))
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Quick prompt data model
struct QuickPrompt: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let text: String
    
    static let defaults: [QuickPrompt] = [
        QuickPrompt(
            icon: "📊",
            title: "Which deps?",
            text: "Which dependencies need updating?"
        ),
        QuickPrompt(
            icon: "🔒",
            title: "Security?",
            text: "Are there any security vulnerabilities in my dependencies?"
        ),
        QuickPrompt(
            icon: "🔄",
            title: "Safe updates?",
            text: "Which dependencies are safe to update without breaking changes?"
        ),
        QuickPrompt(
            icon: "📈",
            title: "Health check",
            text: "What's the overall health of my project dependencies?"
        ),
        QuickPrompt(
            icon: "❓",
            title: "Explain",
            text: "Explain why certain dependencies are flagged as critical"
        )
    ]
}

// MARK: - Preview

#Preview("Quick Prompts") {
    VStack {
        QuickPromptsView(prompts: QuickPrompt.defaults) { text in
            print("Selected: \(text)")
        }
    }
    .background(Theme.background)
}
