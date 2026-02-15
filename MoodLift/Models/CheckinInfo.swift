import Foundation

struct CheckinInfo: Codable, @unchecked Sendable {
    let currentStreak: Int
    let lastCheckin: Date?
    let totalCheckins: Int
    let canCheckin: Bool
    let nextPoints: Int

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case lastCheckin = "last_checkin"
        case totalCheckins = "total_checkins"
        case canCheckin = "can_checkin"
        case nextPoints = "next_points"
    }
}

struct CheckinResponse: Codable, @unchecked Sendable {
    let message: String
    let pointsEarned: Int
    let newStreak: Int
    let totalPoints: Int

    enum CodingKeys: String, CodingKey {
        case message
        case pointsEarned = "points_earned"
        case newStreak = "new_streak"
        case totalPoints = "total_points"
    }
}
