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
    
    /// Next check-in points: 1 on normal days, 6 on every 5th day (1 + 5 bonus). Backend should use the same rule.
    static func calculateNextCheckinPoints(totalCheckins: Int) -> Int {
        let nextDay = totalCheckins + 1
        if nextDay % 5 == 0 { return Constants.dailyCheckinBasePoints + Constants.everyFiveDaysBonusPoints }
        return Constants.dailyCheckinBasePoints
    }
    
    static func getUnlockCost(totalUnlocks: Int) -> Int {
        return totalUnlocks == 0 ? 5 : 15
    }
}
