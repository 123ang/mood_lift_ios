import Foundation

struct ContentItem: Codable, Identifiable, @unchecked Sendable {
    let id: String
    var contentText: String?
    var question: String?
    var answer: String?
    var optionA: String?
    var optionB: String?
    var optionC: String?
    var optionD: String?
    var correctOption: String?
    var author: String?
    let category: String
    let contentType: String  // "text", "quiz", "qa"
    var submittedBy: String?
    var submitterUsername: String?
    var status: String
    var upvotes: Int
    var downvotes: Int
    var reportCount: Int
    var userVote: String?  // "up", "down", or nil
    var isUnlocked: Bool?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case contentText = "content_text"
        case question, answer
        case optionA = "option_a"
        case optionB = "option_b"
        case optionC = "option_c"
        case optionD = "option_d"
        case correctOption = "correct_option"
        case author, category
        case contentType = "content_type"
        case submittedBy = "submitted_by"
        case submitterUsername = "submitter_username"
        case status, upvotes, downvotes
        case reportCount = "report_count"
        case userVote = "user_vote"
        case isUnlocked = "is_unlocked"
        case createdAt = "created_at"
    }

    /// Display text - handles all content types
    var displayText: String {
        switch contentType {
        case "quiz":
            return question ?? contentText ?? ""
        case "qa":
            return question ?? contentText ?? ""
        default:
            return contentText ?? ""
        }
    }

    var score: Int {
        return upvotes - downvotes
    }
}

struct ContentSubmission: Codable {
    let contentText: String?
    let question: String?
    let answer: String?
    let optionA: String?
    let optionB: String?
    let optionC: String?
    let optionD: String?
    let correctOption: String?
    let author: String?
    let category: String
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case contentText = "content_text"
        case question, answer
        case optionA = "option_a"
        case optionB = "option_b"
        case optionC = "option_c"
        case optionD = "option_d"
        case correctOption = "correct_option"
        case author, category
        case contentType = "content_type"
    }
}

struct DailyContentItem: Codable, Identifiable, @unchecked Sendable {
    let id: String
    let contentId: String
    let category: String
    let positionInDay: Int
    let content: ContentItem?
    var isUnlocked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case contentId = "content_id"
        case category
        case positionInDay = "position_in_day"
        case content
        case isUnlocked = "is_unlocked"
    }
}
