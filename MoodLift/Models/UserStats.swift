import Foundation

struct UserStats: Codable {
    let pointsBalance: Int
    let currentStreak: Int
    let totalCheckins: Int
    let totalPointsEarned: Int
    let totalContentSubmitted: Int
    let totalSaved: Int
    let memberSince: Date?

    enum CodingKeys: String, CodingKey {
        case pointsBalance = "points_balance"
        case currentStreak = "current_streak"
        case totalCheckins = "total_checkins"
        case totalPointsEarned = "total_points_earned"
        case totalContentSubmitted = "total_content_submitted"
        case totalSaved = "total_saved"
        case memberSince = "member_since"
    }
}
