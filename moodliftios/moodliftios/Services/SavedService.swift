import Foundation

class SavedService {
    static let shared = SavedService()
    
    func getSavedItems(category: String? = nil) async throws -> [SavedItem] {
        var params: [String: String]? = nil
        if let category = category {
            params = ["category": category]
        }
        let data = try await APIService.shared.requestData(endpoint: "/saved", queryParams: params)
        return try APIDecoder.decode([SavedItem].self, from: data)
    }
    
    func saveItem(contentId: String) async throws {
        let data = try await APIService.shared.requestData(endpoint: "/saved/\(contentId)", method: "POST")
        _ = try APIDecoder.decode(EmptyResponse.self, from: data)
    }
    
    func unsaveItem(contentId: String) async throws {
        let data = try await APIService.shared.requestData(endpoint: "/saved/\(contentId)", method: "DELETE")
        _ = try APIDecoder.decode(EmptyResponse.self, from: data)
    }
}
