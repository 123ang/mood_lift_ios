import SwiftUI

// MARK: - MoodLift Palette — Soft pastel, warm, companion feel. No pure white, no strong red.

extension Color {
    // Primary: soft coral / peach (not strong red)
    static let primarySoft = Color(hex: "#f4a898")
    static let primarySoftLight = Color(hex: "#fce8e5")
    /// Slightly richer tint for hero cards so they don’t blend with app background
    static let primaryCardTint = Color(hex: "#f9dfda")
    static let primaryGradientStart = Color(hex: "#f4a898")
    static let primaryGradientEnd = Color(hex: "#f2c4b3")
    static let brandPrimary = Color(hex: "#e8a598")

    // Secondary: soft sky blue
    static let secondarySoft = Color(hex: "#a8d4e6")
    static let secondarySoftLight = Color(hex: "#e8f4f9")

    // Accent: warm yellow
    static let accentWarm = Color(hex: "#f5e6b8")
    static let accentWarmDarker = Color(hex: "#e8d4a0")

    // Support: mint green (calm success)
    static let supportMint = Color(hex: "#b8e0d0")
    static let supportMintLight = Color(hex: "#e8f7f2")

    // Backgrounds — warm off-white, no pure #FFFFFF
    static let appBackground = Color(hex: "#faf6f4")
    static let cardBackground = Color(hex: "#fefcfb")
    static let cardBackgroundAlt = Color(hex: "#f8f4f2")

    // Text — soft contrast (dark on light backgrounds for readability)
    static let darkText = Color(hex: "#4a4543")
    static let lightText = Color(hex: "#7a7573")
    static let mutedText = Color(hex: "#9c9694")
    /// Placeholder text on light backgrounds (e.g. text fields) — dark enough to read clearly
    static let placeholderOnLight = Color(hex: "#5a5553")

    // Semantic (gentle, not aggressive)
    static let successSoft = Color(hex: "#7bc4a8")
    static let successSoftBg = Color(hex: "#e8f7f2")
    static let reminderSoft = Color(hex: "#e8c88a")
    static let reminderSoftBg = Color(hex: "#fdf8ed")
    static let errorSoft = Color(hex: "#d4a5a5")
    static let errorSoftBg = Color(hex: "#f9eeee")

    // Legacy aliases (map old names to new soft palette)
    static let borderColor = Color(hex: "#d4cfcc")
    static let accentYellow = accentWarm
    static let successGreen = successSoft
    static let warningOrange = reminderSoft
    static let errorRed = errorSoft

    // Category tints (pastel, icon-aligned)
    static let encouragementPink = Color(hex: "#e8a598")
    static let encouragementPinkLight = Color(hex: "#fce8e5")
    static let inspirationYellow = Color(hex: "#e8d4a0")
    static let inspirationYellowLight = Color(hex: "#fdf8ed")
    static let factsGreen = Color(hex: "#a8d4c4")
    static let factsGreenLight = Color(hex: "#e8f5f0")
    static let jokesBlue = Color(hex: "#a8c8e0")
    static let jokesBlueLight = Color(hex: "#e8f2f9")

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

// MARK: - ContentCategory (colors stay aligned with soft palette)
enum ContentCategory: String, CaseIterable {
    case encouragement
    case inspiration
    case facts
    case jokes

    var displayName: String {
        switch self {
        case .encouragement: return "Encouragement"
        case .inspiration: return "Inspiration"
        case .facts: return "Fun Facts"
        case .jokes: return "Jokes"
        }
    }

    var icon: String {
        switch self {
        case .encouragement: return "heart.fill"
        case .inspiration: return "star.fill"
        case .facts: return "brain.head.profile"
        case .jokes: return "face.smiling.fill"
        }
    }

    var imageAssetName: String {
        switch self {
        case .encouragement: return "EncouragementIcon"
        case .inspiration: return "InspirationIcon"
        case .facts: return "FunFactIcon"
        case .jokes: return "JokeIcon"
        }
    }

    var color: Color {
        switch self {
        case .encouragement: return .encouragementPink
        case .inspiration: return .inspirationYellow
        case .facts: return .factsGreen
        case .jokes: return .jokesBlue
        }
    }

    var lightColor: Color {
        switch self {
        case .encouragement: return .encouragementPinkLight
        case .inspiration: return .inspirationYellowLight
        case .facts: return .factsGreenLight
        case .jokes: return .jokesBlueLight
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .encouragement:
            return LinearGradient(colors: [.primaryGradientStart, .primaryGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .inspiration:
            return LinearGradient(colors: [.inspirationYellow, .accentWarmDarker], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .facts:
            return LinearGradient(colors: [.factsGreen, .supportMint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .jokes:
            return LinearGradient(colors: [.jokesBlue, .secondarySoft], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var description: String {
        switch self {
        case .encouragement: return "Uplifting messages to brighten your day"
        case .inspiration: return "Motivational quotes to inspire you"
        case .facts: return "Interesting facts to expand your mind"
        case .jokes: return "Funny jokes to make you smile"
        }
    }
}
