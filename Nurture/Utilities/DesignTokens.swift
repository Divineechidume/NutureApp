//
//  DesignTokens.swift
//  Nurture
//
//  Design tokens from PRD Visual Identity (Section: Color palette, Typography, Spacing).
//  Colors: Sage green (primary), peach/coral (alerts), lavender (accents), cream (backgrounds).
//  Typography: Nunito (headings), Open Sans (body).
//

import SwiftUI

// MARK: - Design Tokens

/// Design tokens from PRD Visual Identity. Use these for consistent calm, nurturing UI.
struct DesignTokens {

    // MARK: - Colors

    /// Primary brand color. Use for asleep state background, primary actions. PRD: Sage green.
    static let sageGreen = Color(red: 0.55, green: 0.65, blue: 0.55)

    /// Dark sage for nighttime sleep bars in History. PRD: dark sage for nighttime.
    static let darkSage = Color(red: 0.35, green: 0.50, blue: 0.40)

    /// Alerts and secondary emphasis. Use for rollover alerts (calm but urgent). PRD: Peach/coral.
    static let peachCoral = Color(red: 0.95, green: 0.70, blue: 0.65)

    /// Accent color for highlights. PRD: Lavender.
    static let lavender = Color(red: 0.75, green: 0.70, blue: 0.90)

    /// Background when awake and general calm backgrounds. PRD: Cream.
    static let cream = Color(red: 0.99, green: 0.98, blue: 0.95)

    /// Text on light backgrounds.
    static let textPrimary = Color.primary
    /// Secondary text.
    static let textSecondary = Color.secondary

    // MARK: - Typography

    // TODO: Bundle custom fonts
    // Purpose: PRD specifies Nunito (headings) and Open Sans (body)
    // PRD Reference: Visual Identity - Typography
    // Implementation notes:
    // - Add Nunito and Open Sans .ttf/.otf to project and Info.plist "Fonts provided by application"
    // - Use Font.custom("Nunito-Regular", size: 20) etc. after bundling
    // Dependencies: None
    // Estimated complexity: Low

    /// Heading font. PRD: Nunito. Falls back to system rounded until fonts are bundled.
    static func headingFont(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Body font. PRD: Open Sans. Falls back to system until fonts are bundled.
    static func bodyFont(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular)
    }

    /// Large title for status (e.g. "Asleep", "Awake").
    static let statusTitleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    /// Caption/secondary text.
    static func captionFont(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular)
    }

    // MARK: - Spacing (PRD: generous whitespace)

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Corner Radius

    /// Cards (status card, info cards).
    static let cardCornerRadius: CGFloat = 16
    /// Buttons.
    static let buttonCornerRadius: CGFloat = 12
}
