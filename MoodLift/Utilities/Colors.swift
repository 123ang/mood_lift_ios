import SwiftUI

extension Color {
    // Category colors
    static let encouragementPink = Color(hex: "#ff6b6b")
    static let encouragementPinkLight = Color(hex: "#ffebea")
    static let inspirationYellow = Color(hex: "#ffd93d")
    static let inspirationYellowLight = Color(hex: "#fff9e6")
    static let factsGreen = Color(hex: "#4ecdc4")
    static let factsGreenLight = Color(hex: "#e8faf8")
    static let jokesBlue = Color(hex: "#45b7d1")
    static let jokesBlueLight = Color(hex: "#e6f4f9")
    
    // UI Colors
    static let appBackground = Color(hex: "#fff5f5")
    static let cardBackground = Color.white
    static let darkText = Color(hex: "#333333")
    static let lightText = Color(hex: "#666666")
    static let borderColor = Color(hex: "#4d4d4d")
    static let accentYellow = Color(hex: "#fcee21")
    static let successGreen = Color(hex: "#2ecc71")
    static let warningOrange = Color(hex: "#f39c12")
    static let errorRed = Color(hex: "#e74c3c")
    
    // Gradient pairs
    static let primaryGradientStart = Color(hex: "#ff6b6b")
    static let primaryGradientEnd = Color(hex: "#ee5a24")
    
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

// Category helpers
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
            return LinearGradient(colors: [Color(hex: "#ff6b6b"), Color(hex: "#ee5a24")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .inspiration:
            return LinearGradient(colors: [Color(hex: "#ffd93d"), Color(hex: "#f39c12")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .facts:
            return LinearGradient(colors: [Color(hex: "#4ecdc4"), Color(hex: "#2ecc71")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .jokes:
            return LinearGradient(colors: [Color(hex: "#45b7d1"), Color(hex: "#3498db")], startPoint: .topLeading, endPoint: .bottomTrailing)
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
