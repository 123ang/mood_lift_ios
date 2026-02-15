import Foundation

enum Constants {
    static let appName = "MoodLift"
    static let appVersion = "1.0.0"

    /// API base URL. Debug = local backend; Release = deployed backend (required for TestFlight / App Store).
    #if DEBUG
    static let apiBaseURL = "http://localhost:3000/api"
    #else
    /// ⚠️ Replace with your real deployed backend URL before shipping (e.g. https://your-app.herokuapp.com/api)
    static let apiBaseURL = "https://YOUR_PRODUCTION_API_URL/api"
    #endif
    
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
