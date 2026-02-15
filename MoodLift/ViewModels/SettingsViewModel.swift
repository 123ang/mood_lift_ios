import Foundation

@Observable
class SettingsViewModel {
    var notificationsEnabled: Bool = true
    var reminderHour: Int = 8
    var reminderMinute: Int = 0
    var isLoading = false
    var showChangePassword = false
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    var errorMessage: String?
    var successMessage: String?
    
    func loadSettings() {
        if let user = AuthService.shared.currentUser {
            notificationsEnabled = user.notificationsEnabled
            if let timeStr = user.notificationTime {
                let parts = timeStr.split(separator: ":")
                if parts.count >= 2 {
                    reminderHour = Int(parts[0]) ?? 8
                    reminderMinute = Int(parts[1]) ?? 0
                }
            }
        }
    }
    
    func toggleNotifications() async {
        notificationsEnabled.toggle()
        if notificationsEnabled {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                await NotificationService.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
            } else {
                notificationsEnabled = false
                errorMessage = "Please enable notifications in Settings"
            }
        } else {
            NotificationService.shared.cancelAllReminders()
        }
    }
    
    func updateReminderTime() async {
        if notificationsEnabled {
            await NotificationService.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
        }
    }
    
    func changePassword() async {
        guard !currentPassword.isEmpty, !newPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AuthService.shared.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            successMessage = "Password changed successfully"
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            showChangePassword = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() async {
        await AuthService.shared.logout()
    }
}
