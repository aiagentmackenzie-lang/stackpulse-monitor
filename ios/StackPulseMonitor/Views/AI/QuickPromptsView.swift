import SwiftUI

/// Grid of quick action prompts for AI chat
struct QuickPromptsView: View {
    let prompts: [QuickPrompt]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Row 1
            HStack(spacing: 10) {
                if prompts.count > 0 {
                    PromptChip(prompt: prompts[0]) {
                        onSelect(prompts[0].text)
                    }
                }
                if prompts.count > 1 {
                    PromptChip(prompt: prompts[1]) {
                        onSelect(prompts[1].text)
                    }
                }
            }
            
            // Row 2
            HStack(spacing: 10) {
                if prompts.count > 2 {
                    PromptChip(prompt: prompts[2]) {
                        onSelect(prompts[2].text)
                    }
                }
                if prompts.count > 3 {
                    PromptChip(prompt: prompts[3]) {
                        onSelect(prompts[3].text)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.purple.opacity(0.15))
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
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
            text: "Are there any security vulnerabilities?"
        ),
        QuickPrompt(
            icon: "🔄",
            title: "Safe updates?",
            text: "Which are safe to update?"
        ),
        QuickPrompt(
            icon: "📈",
            title: "Health",
            text: "What's my project health?"
        )
    ]
}

// MARK: - Preview

#Preview("Quick Prompts Grid") {
    VStack {
        QuickPromptsView(prompts: QuickPrompt.defaults) { text in
            print("Selected: \(text)")
        }
    }
    .background(Theme.background)
}
