import Foundation

struct SavedItem: Codable, Identifiable, Sendable {
    let id: String
    let contentId: String
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
    let savedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case contentId = "content_id"
        case contentText = "content_text"
        case question, answer
        case optionA = "option_a"
        case optionB = "option_b"
        case optionC = "option_c"
        case optionD = "option_d"
        case correctOption = "correct_option"
        case author, category
        case contentType = "content_type"
        case savedAt = "saved_at"
    }

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
}
