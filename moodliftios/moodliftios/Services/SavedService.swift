import Foundation

class SavedService {
    static let shared = SavedService()
    
    func getSavedItems(category: String? = nil) async throws -> [SavedItem] {
        var params: [String: String]? = nil
        if let category = category {
            params = ["category": category]
        }
        return try await APIService.shared.request(
            endpoint: "/saved",
            queryParams: params
        )
    }
    
    func saveItem(contentId: String) async throws {
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/saved/\(contentId)",
            method: "POST"
        )
    }
    
    func unsaveItem(contentId: String) async throws {
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/saved/\(contentId)",
            method: "DELETE"
        )
    }
}
