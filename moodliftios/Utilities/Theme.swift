import SwiftUI

// MARK: - MoodLift Design System
// Soft pastel, friendly mental-wellness companion. Calm, cozy, rounded. No harsh contrast or productivity look.

enum Theme {
    // MARK: - Radius (large, friendly rounding)
    static let radiusSmall: CGFloat = 14
    static let radiusMedium: CGFloat = 20
    static let radiusLarge: CGFloat = 24
    static let radiusXLarge: CGFloat = 28
    static let radiusPill: CGFloat = 999

    // MARK: - Spacing (breathing room)
    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 16
    static let spaceL: CGFloat = 24
    static let spaceXL: CGFloat = 32
    static let spaceXXL: CGFloat = 40

    // MARK: - Shadows
    static func softShadow(opacity: Double = 0.06, radius: CGFloat = 8, y: CGFloat = 3) -> (color: Color, radius: CGFloat, y: CGFloat) {
        (Color.black.opacity(opacity), radius, y)
    }
    static func cardShadow() -> (color: Color, radius: CGFloat, y: CGFloat) {
        softShadow(opacity: 0.05, radius: 10, y: 4)
    }
    /// Stronger shadow so cards read clearly off the background
    static func elevatedCardShadow() -> (color: Color, radius: CGFloat, y: CGFloat) {
        (Color.black.opacity(0.12), 16, 6)
    }
}

// MARK: - Typography (friendly, rounded, varied for hierarchy)
extension Font {
    /// Large display title for app name / hero
    static func themeDisplayTitle() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    /// Section / screen title
    static func themeTitle() -> Font { .system(size: 24, weight: .bold, design: .rounded) }
    static func themeTitleSmall() -> Font { .system(size: 20, weight: .bold, design: .rounded) }
    static func themeHeadline() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func themeSubheadline() -> Font { .system(size: 15, weight: .medium, design: .rounded) }
    static func themeBody() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func themeBodyMedium() -> Font { .system(size: 15, weight: .medium, design: .rounded) }
    static func themeCallout() -> Font { .system(size: 14, weight: .regular, design: .rounded) }
    static func themeCaption() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
    static func themeCaptionMedium() -> Font { .system(size: 12, weight: .medium, design: .rounded) }
}
