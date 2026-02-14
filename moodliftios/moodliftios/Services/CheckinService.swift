import Foundation

class CheckinService {
    static let shared = CheckinService()
    
    func getCheckinInfo() async throws -> CheckinInfo {
        let data = try await APIService.shared.requestData(endpoint: "/checkin/info")
        return try APIDecoder.decode(CheckinInfo.self, from: data)
    }
    
    func performCheckin() async throws -> CheckinResponse {
        let data = try await APIService.shared.requestData(endpoint: "/checkin", method: "POST")
        return try APIDecoder.decode(CheckinResponse.self, from: data)
    }
}
