import Foundation

struct APIErrorResponse: Codable {
    let error: String
}

enum APIError: LocalizedError {
    case networkError(String)
    case serverError(String)
    case authError(String)
    case validationError(String)
    case decodingError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        case .authError(let msg): return msg
        case .validationError(let msg): return msg
        case .decodingError(let msg): return msg
        case .unknown: return "An unknown error occurred"
        }
    }
    
    var userMessage: String {
        errorDescription ?? "An unknown error occurred"
    }
}
