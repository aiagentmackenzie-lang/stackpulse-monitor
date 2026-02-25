import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: Theme.cardShadowColor.opacity(Theme.cardShadowOpacity), radius: 8, y: 4)
    }
}

extension TechStatus {
    var label: String {
        switch self {
        case .ok: return "UP TO DATE"
        case .update: return "UPDATE AVAIL"
        case .critical: return "CVE FOUND"
        case .eol: return "END OF LIFE"
        case .unknown: return "UNKNOWN"
        }
    }

    var color: Color {
        switch self {
        case .ok: return Theme.success
        case .update: return Theme.warning
        case .critical: return Theme.danger
        case .eol: return Color(hex: 0x6B7280)
        case .unknown: return Theme.muted
        }
    }

    var icon: String {
        switch self {
        case .ok: return "checkmark.circle.fill"
        case .update: return "exclamationmark.triangle.fill"
        case .critical: return "shield.exclamationmark.fill"
        case .eol: return "clock.badge.exclamationmark.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

extension AlertType {
    var color: Color {
        switch self {
        case .critical: return Theme.danger
        case .update: return Theme.warning
        case .eol: return Color(hex: 0x6B7280)
        case .breaking: return Theme.warning
        }
    }

    var icon: String {
        switch self {
        case .critical: return "shield.exclamationmark.fill"
        case .update: return "arrow.up.circle.fill"
        case .eol: return "clock.badge.exclamationmark.fill"
        case .breaking: return "exclamationmark.triangle.fill"
        }
    }

    var label: String {
        switch self {
        case .critical: return "CRITICAL CVE"
        case .update: return "MAJOR UPDATE"
        case .eol: return "END OF LIFE"
        case .breaking: return "BREAKING CHANGE"
        }
    }
}

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
