//
//  DesignTokens.swift
//  Nurture
//
//  Design tokens from PRD Visual Identity. Colors: Sage green, peach/coral, lavender, cream.
//  Typography: Nunito (headings), Open Sans (body). Shadows, spacing, corner radius.
//

import SwiftUI

// MARK: - Design Tokens (Legacy)

/// Design tokens from PRD Visual Identity. Use these for consistent calm, nurturing UI.
struct DesignTokens {

    // MARK: - Colors

    /// Primary brand color. Use for asleep state background, primary actions. PRD: Sage green #8B9D83.
    static let sageGreen = Color(hex: "8B9D83")

    /// Dark sage for nighttime sleep bars in History. PRD: dark sage for nighttime.
    static let darkSage = Color(red: 0.35, green: 0.50, blue: 0.40)

    /// Alerts and secondary emphasis. Use sparingly. PRD: Peach/coral #F4A59F.
    static let peachCoral = Color(hex: "F4A59F")

    /// Accent color for highlights, informational alerts (FDA-compliant). PRD: Lavender #C5B9D6.
    static let lavender = Color(hex: "C5B9D6")

    /// Background when awake and general calm backgrounds. PRD: Cream #F5F1E8.
    static let cream = Color(hex: "F5F1E8")

    /// Text on light backgrounds. PRD: #2D3436.
    static let textPrimary = Color(hex: "2D3436")
    /// Secondary text. PRD: #636E72.
    static let textSecondary = Color(hex: "636E72")

    // MARK: - Typography (Legacy - prefer Font extensions below)

    static func headingFont(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func bodyFont(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular)
    }

    static let statusTitleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static func captionFont(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular)
    }

    // MARK: - Spacing (8pt grid)

    static let spacingXS: CGFloat = 8
    static let spacingSM: CGFloat = 16
    static let spacingMD: CGFloat = 24
    static let spacingLG: CGFloat = 32
    static let spacingXL: CGFloat = 40
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radius

    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
}

// MARK: - Typography Extensions

extension Font {
    // Display (Nunito Bold - system bold rounded fallback)
    static let displayLarge = Font.system(size: 40, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)

    // Headings (Nunito SemiBold)
    static let headingLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let headingMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headingSmall = Font.system(size: 18, weight: .semibold, design: .rounded)

    // Body (Open Sans Regular)
    static let bodyLarge = Font.system(size: 18, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)

    // Labels (Open Sans SemiBold)
    static let labelLarge = Font.system(size: 16, weight: .semibold)
    static let labelMedium = Font.system(size: 14, weight: .semibold)
    static let labelSmall = Font.system(size: 12, weight: .semibold)
}

// MARK: - Color Extensions

extension Color {
    static let sageGreen = DesignTokens.sageGreen
    static let peachCoral = DesignTokens.peachCoral
    static let lavender = DesignTokens.lavender
    static let cream = DesignTokens.cream
    static let textPrimary = DesignTokens.textPrimary
    static let textSecondary = DesignTokens.textSecondary
    static let sleepBackground = DesignTokens.sageGreen
    static let awakeBackground = DesignTokens.cream
    static let alertAccent = DesignTokens.lavender
    static let cardBackground = Color.white
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Shadow Extensions

extension View {
    func cardShadowPrimary() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
    }

    func cardShadowSecondary() -> some View {
        self.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    func elevatedShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -2)
    }
}

// MARK: - Spacing

struct Spacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 16
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 40
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct CornerRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}
