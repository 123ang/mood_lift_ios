import Foundation

class ContentService {
    static let shared = ContentService()
    
    func getContent(category: String, page: Int = 1, limit: Int = 20, sort: String = "newest", includePending: Bool = false) async throws -> [ContentItem] {
        var params = ["page": "\(page)", "limit": "\(limit)", "sort": sort]
        if includePending { params["include_pending"] = "1" }
        let data = try await APIService.shared.requestData(endpoint: "/content/\(category)", queryParams: params)
        let response = try APIDecoder.decode(ContentListResponse.self, from: data)
        return response.data
    }
    
    func getDailyContent(category: String) async throws -> [DailyContentItem] {
        let data = try await APIService.shared.requestData(endpoint: "/content/\(category)/daily")
        return try APIDecoder.decode([DailyContentItem].self, from: data)
    }

    /// Community feed: user-submitted content visible to everyone (Instagram/Facebook style).
    /// Sends include_pending=1 so the backend can return pending submissions in the feed if supported.
    func getFeedContent(page: Int = 1, limit: Int = 20) async throws -> [ContentItem] {
        var params = ["page": "\(page)", "limit": "\(limit)", "sort": "newest"]
        params["include_pending"] = "1"  // so newly submitted content shows in feed (backend may filter by this)
        let data = try await APIService.shared.requestData(endpoint: "/content/feed", queryParams: params)
        let response = try APIDecoder.decode(ContentListResponse.self, from: data)
        return response.data
    }

    /// Content submitted by the current user (for Profile "My Content"). Tries GET /content/mine; if unavailable, filters feed by submittedBy.
    func getMyContent(page: Int = 1, limit: Int = 50) async throws -> [ContentItem] {
        do {
            let params = ["page": "\(page)", "limit": "\(limit)", "sort": "newest"]
            let data = try await APIService.shared.requestData(endpoint: "/content/mine", queryParams: params)
            let response = try APIDecoder.decode(ContentListResponse.self, from: data)
            return response.data
        } catch {
            // Backend may not have /content/mine: fall back to feed filtered by current user
            guard let userId = AuthService.shared.currentUser?.id else { return [] }
            let feed = try await getFeedContent(page: page, limit: max(limit, 100))
            return feed.filter { $0.submittedBy == userId }
        }
    }
    
    func submitContent(_ submission: ContentSubmission) async throws -> ContentItem {
        let data = try await APIService.shared.requestData(endpoint: "/content/submit", method: "POST", body: submission)
        return try APIDecoder.decode(ContentItem.self, from: data)
    }
    
    func voteOnContent(contentId: String, voteType: String) async throws -> ContentItem {
        struct VoteBody: Codable {
            let voteType: String
            enum CodingKeys: String, CodingKey {
                case voteType = "vote_type"
            }
        }
        let data = try await APIService.shared.requestData(
            endpoint: "/content/\(contentId)/vote",
            method: "POST",
            body: VoteBody(voteType: voteType)
        )
        return try APIDecoder.decode(ContentItem.self, from: data)
    }
    
    func reportContent(contentId: String, reason: String) async throws {
        struct ReportBody: Codable {
            let reason: String
        }
        let data = try await APIService.shared.requestData(
            endpoint: "/content/\(contentId)/report",
            method: "POST",
            body: ReportBody(reason: reason)
        )
        _ = try APIDecoder.decode(EmptyResponse.self, from: data)
    }
    
    func unlockContent(contentId: String) async throws -> UnlockResponse {
        let data = try await APIService.shared.requestData(endpoint: "/content/\(contentId)/unlock", method: "POST")
        return try APIDecoder.decode(UnlockResponse.self, from: data)
    }
}

struct ContentListResponse: Codable, @unchecked Sendable {
    let data: [ContentItem]
    let total: Int
    let page: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case data, total, page
        case totalPages = "total_pages"
    }
}

struct UnlockResponse: Codable, @unchecked Sendable {
    let message: String
    let pointsSpent: Int
    let remainingBalance: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case pointsSpent = "points_spent"
        case remainingBalance = "remaining_balance"
    }
}
