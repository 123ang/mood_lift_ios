import Foundation

enum Constants {
    static let appName = "MoodLift"
    static let appVersion = "1.0.0"
    
    // Points
    static let initialPoints = 5
    static let firstUnlockCost = 5
    static let subsequentUnlockCost = 15
    static let maxDailyContentPerCategory = 10
    
    // Cache keys
    static let cachedContentPrefix = "cached_content_"
    static let lastSyncDate = "last_sync_date"
    static let cachedUserProfile = "cached_user_profile"
    
    // Notification
    static let defaultReminderHour = 8
    static let defaultReminderMinute = 0
}
