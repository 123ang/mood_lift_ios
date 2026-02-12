import Foundation

class PointsService {
    static let shared = PointsService()
    
    func getPointsHistory(page: Int = 1, limit: Int = 50) async throws -> PaginatedResponse<PointsTransaction> {
        let params = ["page": "\(page)", "limit": "\(limit)"]
        return try await APIService.shared.request(
            endpoint: "/users/points-history",
            queryParams: params
        )
    }
    
    func getUserStats() async throws -> UserStats {
        return try await APIService.shared.request(endpoint: "/users/stats")
    }
    
    // Local calculation helpers
    static func calculateDailyPoints(streak: Int) -> Int {
        if streak <= 6 { return 1 }
        let points = Int(round(Double(5) / 7.0 * Double(streak)))
        // Check 30-day bonus
        if streak % 30 == 0 {
            return points + 10
        }
        return points
    }
    
    static func getUnlockCost(totalUnlocks: Int) -> Int {
        return totalUnlocks == 0 ? 5 : 15
    }
}
