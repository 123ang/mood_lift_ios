import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleDailyReminder(hour: Int, minute: Int) async {
        // Cancel existing reminders first
        cancelAllReminders()
        
        let content = UNMutableNotificationContent()
        content.title = "MoodLift"
        content.body = "Time for your daily mood boost! Check in to keep your streak going."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "moodlift.daily.reminder", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getScheduledReminder() async -> DateComponents? {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard let reminder = requests.first(where: { $0.identifier == "moodlift.daily.reminder" }),
              let trigger = reminder.trigger as? UNCalendarNotificationTrigger else {
            return nil
        }
        return trigger.dateComponents
    }
}
