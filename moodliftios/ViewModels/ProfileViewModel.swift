import Foundation

@Observable
class ProfileViewModel {
    var stats: UserStats?
    var recentTransactions: [PointsTransaction] = []
    var isLoading = false
    var errorMessage: String?
    
    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let statsTask = PointsService.shared.getUserStats()
            async let historyTask = PointsService.shared.getPointsHistory(page: 1, limit: 5)
            
            let (fetchedStats, history) = try await (statsTask, historyTask)
            stats = fetchedStats
            recentTransactions = history.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
