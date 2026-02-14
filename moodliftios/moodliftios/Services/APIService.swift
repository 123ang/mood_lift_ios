import Foundation

// Decoding runs in the caller’s context so Decodable types can be main-actor isolated if needed.
enum APIDecoder {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd"
            ]
            for format in formatters {
                let df = DateFormatter()
                df.dateFormat = format
                df.locale = Locale(identifier: "en_US_POSIX")
                df.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = df.date(from: dateString) { return date }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return d
    }()
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}

actor APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api"
    private var authToken: String?
    
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()
    
    func setToken(_ token: String?) {
        self.authToken = token
    }
    
    func getToken() -> String? {
        return authToken
    }
    
    /// Returns raw response data. Decode in the caller with `APIDecoder.decode(_:from:)` to avoid main-actor isolation issues.
    func requestData(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> Data {
        var urlString = "\(baseURL)\(endpoint)"
        if let params = queryParams {
            var components = URLComponents(string: urlString)!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = components.url!.absoluteString
        }
        guard let url = URL(string: urlString) else {
            throw APIError.networkError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }
        if httpResponse.statusCode == 401 {
            throw APIError.authError("Authentication required")
        }
        if httpResponse.statusCode >= 400 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? String {
                throw APIError.serverError(error)
            }
            throw APIError.serverError("Server error: \(httpResponse.statusCode)")
        }
        return data
    }
}

// Helpers (Sendable so they can be used across actor isolation)
struct EmptyResponse: Decodable, @unchecked Sendable {}

struct AnyEncodable: Encodable, @unchecked Sendable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
