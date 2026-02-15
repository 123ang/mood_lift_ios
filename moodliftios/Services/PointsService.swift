import Foundation

class PointsService {
    static let shared = PointsService()
    
    @MainActor
    func getPointsHistory(page: Int = 1, limit: Int = 50) async throws -> PaginatedResponse<PointsTransaction> {
        let params = ["page": "\(page)", "limit": "\(limit)"]
        let data = try await APIService.shared.requestData(endpoint: "/users/points-history", queryParams: params)
        return try APIDecoder.decode(PaginatedResponse<PointsTransaction>.self, from: data)
    }
    
    func getUserStats() async throws -> UserStats {
        let data = try await APIService.shared.requestData(endpoint: "/users/stats")
        return try APIDecoder.decode(UserStats.self, from: data)
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
