import Foundation

class CheckinService {
    static let shared = CheckinService()
    
    func getCheckinInfo() async throws -> CheckinInfo {
        return try await APIService.shared.request(endpoint: "/checkin/info")
    }
    
    func performCheckin() async throws -> CheckinResponse {
        return try await APIService.shared.request(
            endpoint: "/checkin",
            method: "POST"
        )
    }
}
