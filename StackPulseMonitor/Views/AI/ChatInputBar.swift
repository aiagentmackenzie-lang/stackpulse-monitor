import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let isStreaming: Bool
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input
            TextField("Ask anything...", text: $text, axis: .vertical)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .tint(.purple)
                .focused($isFocused)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: 0x2A2A2A))
                .clipShape(.rect(cornerRadius: 20))
            
            // Send button
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(text.isEmpty ? Theme.border : Color.purple)
                        .frame(width: 36, height: 36)
                    
                    if isStreaming {
                        // Loading indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(text.isEmpty || isStreaming)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            Divider()
                .background(Theme.border)
                .frame(maxHeight: .infinity, alignment: .top)
        )
    }
}

#Preview("Input Bar") {
    @Previewable @State var text = ""
    ChatInputBar(text: $text, onSend: {}, isStreaming: false)
}
