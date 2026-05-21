import SwiftUI

// Central design tokens — keeps the LinkUP brand styling in one place.
enum Theme {
    // Brand
    static let brand = Color(hex: 0x5246EF)
    static let brandDark = Color(hex: 0x3A2FC0)

    // Surfaces
    static let background = Color(hex: 0xF4F4F8)
    static let card = Color.white

    // Text
    static let textPrimary = Color(hex: 0x1A1A2E)
    static let textSecondary = Color(hex: 0x8A8A9A)

    // Status accents
    static let statusNew = Color(hex: 0x5246EF)
    static let statusInProgress = Color(hex: 0xF5A623)
    static let statusClosed = Color(hex: 0x9A9AA8)

    // Metrics
    static let cardRadius: CGFloat = 14
    static let controlRadius: CGFloat = 12
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1,
        )
    }
}

extension LeadStatus {
    var color: Color {
        switch self {
        case .new: return Theme.statusNew
        case .inProgress: return Theme.statusInProgress
        case .closed: return Theme.statusClosed
        }
    }
}
