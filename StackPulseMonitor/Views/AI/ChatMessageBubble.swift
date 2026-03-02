import SwiftUI

struct ChatMessageBubble: View {
    let message: AIMessage
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isUser ? .white : Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? Color.purple
                            : Color(hex: 0x2A2A2A)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                
                // Timestamp
                Text(formattedTime(message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 4)
            }
            
            if !isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview("Chat Bubbles") {
    VStack(spacing: 12) {
        ChatMessageBubble(
            message: AIMessage(role: .assistant, content: "Hello! I can help you analyze your dependencies."),
            isUser: false
        )
        ChatMessageBubble(
            message: AIMessage(role: .user, content: "Which dependencies need updating?"),
            isUser: true
        )
    }
    .background(Theme.background)
}
