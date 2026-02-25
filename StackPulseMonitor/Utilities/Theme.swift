import SwiftUI

enum Theme {
    static let background = Color(hex: 0x0D0D0D)
    static let cardBackground = Color(hex: 0x161616)
    static let accent = Color(hex: 0x6366F1)
    static let success = Color(hex: 0x10B981)
    static let warning = Color(hex: 0xF59E0B)
    static let danger = Color(hex: 0xEF4444)
    static let muted = Color(hex: 0x404040)
    static let textPrimary = Color(hex: 0xF1F5F9)
    static let textSecondary = Color(hex: 0x94A3B8)
    static let border = Color(hex: 0x6366F1).opacity(0.2)
    static let cardRadius: CGFloat = 12
    static let cardShadowColor = Color(hex: 0x6366F1)
    static let cardShadowOpacity: CGFloat = 0.12
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
