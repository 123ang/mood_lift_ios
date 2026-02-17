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
    /// Free points awarded when the user submits content (backend should also award and record in points_transactions).
    static let pointsRewardForContentSubmission = 1
    
    // Cache keys
    static let cachedContentPrefix = "cached_content_"
    static let lastSyncDate = "last_sync_date"
    static let cachedUserProfile = "cached_user_profile"
    
    // Notification
    static let defaultReminderHour = 8
    static let defaultReminderMinute = 0
}
