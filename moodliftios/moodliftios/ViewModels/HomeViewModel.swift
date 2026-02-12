import Foundation

@Observable
class HomeViewModel {
    var checkinInfo: CheckinInfo?
    var isLoading = false
    var isCheckingIn = false
    var errorMessage: String?
    var showCheckinSuccess = false
    var pointsEarned = 0
    
    func loadCheckinInfo() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            checkinInfo = try await CheckinService.shared.getCheckinInfo()
            CacheManager.shared.cacheCheckinInfo(checkinInfo!)
        } catch {
            // Try cache
            checkinInfo = CacheManager.shared.getCachedCheckinInfo()
            if checkinInfo == nil {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func performCheckin() async {
        isCheckingIn = true
        defer { isCheckingIn = false }
        
        do {
            let response = try await CheckinService.shared.performCheckin()
            pointsEarned = response.pointsEarned
            showCheckinSuccess = true
            // Refresh info
            await loadCheckinInfo()
            // Refresh user profile
            await AuthService.shared.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
