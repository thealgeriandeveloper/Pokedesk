import SwiftUI

/// Centralized design tokens derived from the Stitch `DESIGN.md` for Pokedesk.
/// "Collector's Sanctuary" — clean, warm, amber-accented, hyper-rounded.
enum Theme {

    // MARK: - Colors

    enum Colors {
        /// Off-white app background (#FBF9F6)
        static let background = Color(hex: 0xFBF9F6)
        /// White container surface (#FFFFFF)
        static let surface = Color(hex: 0xFFFFFF)
        /// Low-emphasis container (#F5F3F0)
        static let surfaceLow = Color(hex: 0xF5F3F0)
        /// Slightly darker container (#EFEEEB)
        static let surfaceContainer = Color(hex: 0xEFEEEB)

        /// Primary amber accent (#F5A623)
        static let primary = Color(hex: 0xF5A623)
        /// Lighter amber used in gradients (#FFC107)
        static let primaryBright = Color(hex: 0xFFC107)
        /// Deep amber for text-on-light emphasis (#835500)
        static let primaryDeep = Color(hex: 0x835500)
        /// Unfilled progress track (#FBEED8)
        static let progressTrack = Color(hex: 0xFBEED8)

        /// Near-black primary text (#1B1C1A)
        static let onSurface = Color(hex: 0x1B1C1A)
        /// Light grey secondary labels (#8E8E93)
        static let secondaryLabel = Color(hex: 0x8E8E93)
        /// Dark quantity badge background (#1A1A1A)
        static let badge = Color(hex: 0x1A1A1A)

        /// Positive market trend (forest green)
        static let positive = Color(hex: 0x2E9E5B)
        /// Negative market trend (ruby red)
        static let negative = Color(hex: 0xD8443C)

        /// Warm amber gradient (135°) used on hero cards and CTAs.
        static let amberGradient = LinearGradient(
            colors: [primary, primaryBright],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography (Plus Jakarta Sans → system rounded fallback)

    enum Typography {
        static let displayLg = Font.system(size: 32, weight: .heavy, design: .rounded)
        static let headlineMd = Font.system(size: 24, weight: .bold, design: .rounded)
        static let headlineSm = Font.system(size: 20, weight: .bold, design: .rounded)
        static let bodyLg = Font.system(size: 17, weight: .medium, design: .rounded)
        static let bodyMd = Font.system(size: 15, weight: .regular, design: .rounded)
        static let labelSm = Font.system(size: 13, weight: .semibold, design: .rounded)
        static let priceMd = Font.system(size: 17, weight: .heavy, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let base: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        /// Standard mobile side margin.
        static let margin: CGFloat = 20
    }

    // MARK: - Radii

    enum Radius {
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }
}

// MARK: - Hex color helper

extension Color {
    /// Initialize from a 24-bit RGB hex literal, e.g. `Color(hex: 0xF5A623)`.
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Shared view modifiers

extension View {
    /// Level 1 ambient shadow used on content cards.
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.04), radius: 20, x: 0, y: 4)
    }

    /// Level 2 amber shadow used on floating CTAs.
    func ctaShadow() -> some View {
        shadow(color: Theme.Colors.primary.opacity(0.3), radius: 24, x: 0, y: 8)
    }
}
