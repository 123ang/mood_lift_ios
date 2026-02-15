import Foundation

struct PointsTransaction: Codable, Identifiable, Sendable {
    let id: String
    let transactionType: String  // "earned" or "spent"
    let pointsAmount: Int
    let description: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionType = "transaction_type"
        case pointsAmount = "points_amount"
        case description
        case createdAt = "created_at"
    }

    var isEarned: Bool {
        return transactionType == "earned"
    }
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let total: Int
    let page: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case data, total, page
        case totalPages = "total_pages"
    }
}
