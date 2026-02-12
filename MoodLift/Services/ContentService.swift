import Foundation

class ContentService {
    static let shared = ContentService()
    
    func getContent(category: String, page: Int = 1, limit: Int = 20, sort: String = "newest") async throws -> [ContentItem] {
        let params = ["page": "\(page)", "limit": "\(limit)", "sort": sort]
        let response: ContentListResponse = try await APIService.shared.request(
            endpoint: "/content/\(category)",
            queryParams: params
        )
        return response.data
    }
    
    func getDailyContent(category: String) async throws -> [DailyContentItem] {
        return try await APIService.shared.request(endpoint: "/content/\(category)/daily")
    }
    
    func submitContent(_ submission: ContentSubmission) async throws -> ContentItem {
        return try await APIService.shared.request(
            endpoint: "/content/submit",
            method: "POST",
            body: submission
        )
    }
    
    func voteOnContent(contentId: String, voteType: String) async throws -> ContentItem {
        struct VoteBody: Codable {
            let voteType: String
            enum CodingKeys: String, CodingKey {
                case voteType = "vote_type"
            }
        }
        return try await APIService.shared.request(
            endpoint: "/content/\(contentId)/vote",
            method: "POST",
            body: VoteBody(voteType: voteType)
        )
    }
    
    func reportContent(contentId: String, reason: String) async throws {
        struct ReportBody: Codable {
            let reason: String
        }
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/content/\(contentId)/report",
            method: "POST",
            body: ReportBody(reason: reason)
        )
    }
    
    func unlockContent(contentId: String) async throws -> UnlockResponse {
        return try await APIService.shared.request(
            endpoint: "/content/\(contentId)/unlock",
            method: "POST"
        )
    }
}

struct ContentListResponse: Codable {
    let data: [ContentItem]
    let total: Int
    let page: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case data, total, page
        case totalPages = "total_pages"
    }
}

struct UnlockResponse: Codable {
    let message: String
    let pointsSpent: Int
    let remainingBalance: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case pointsSpent = "points_spent"
        case remainingBalance = "remaining_balance"
    }
}
