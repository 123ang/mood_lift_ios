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
            // Update balance from check-in response so Points shows 6 (5 + 1) immediately
            await AuthService.shared.updateBalanceFromCheckin(totalPoints: response.totalPoints)
            // Refresh check-in info (streak, canCheckin) — skip refreshProfile so we don’t overwrite balance with server’s stale 5
            await loadCheckinInfo()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
