import Foundation

enum Constants {
    static let appName = "MoodLift"
    static let appVersion = "1.0.0"

    /// API base URL. Uses remote database so sign-in and register work from device and Simulator.
    /// For local backend development, temporarily set to "http://localhost:3000/api" (or your Mac’s IP on device).
    static let apiBaseURL = "https://moodlift.suntzutechnologies.com/api"
    
    // Points
    static let initialPoints = 5
    /// Cost in points to unlock one locked content item (shown as "Unlock by 5 points" in the app).
    static let firstUnlockCost = 5
    static let subsequentUnlockCost = 5
    /// Max number of items the user can see and unlock per category per day (e.g. 2 = first free + one paid).
    static let maxDailyContentPerCategory = 2
    /// Points awarded when the user submits content (backend must award this and record in points_transactions).
    static let pointsRewardForContentSubmission = 1
    /// Points for a normal daily check-in (backend must use this; every 5th day add everyFiveDaysBonusPoints).
    static let dailyCheckinBasePoints = 1
    /// Extra points on every 5th check-in day (day 5, 10, 15, …). That day total = dailyCheckinBasePoints + this = 6.
    static let everyFiveDaysBonusPoints = 5
    
    // Cache keys
    static let cachedContentPrefix = "cached_content_"
    static let lastSyncDate = "last_sync_date"
    static let cachedUserProfile = "cached_user_profile"
    
    // Notification
    static let defaultReminderHour = 8
    static let defaultReminderMinute = 0
}
