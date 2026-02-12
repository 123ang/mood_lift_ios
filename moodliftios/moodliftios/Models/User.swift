import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let username: String
    var points: Int
    var pointsBalance: Int
    var currentStreak: Int
    var lastCheckin: Date?
    var totalCheckins: Int
    var totalPointsEarned: Int
    var notificationTime: String?  // "HH:mm:ss" format
    var notificationsEnabled: Bool
    let isAdmin: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, username, points
        case pointsBalance = "points_balance"
        case currentStreak = "current_streak"
        case lastCheckin = "last_checkin"
        case totalCheckins = "total_checkins"
        case totalPointsEarned = "total_points_earned"
        case notificationTime = "notification_time"
        case notificationsEnabled = "notifications_enabled"
        case isAdmin = "is_admin"
        case createdAt = "created_at"
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}
