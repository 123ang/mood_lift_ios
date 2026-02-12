import Foundation
import Security

@Observable
class AuthService {
    static let shared = AuthService()
    
    var currentUser: User?
    var isAuthenticated: Bool = false
    var isLoading: Bool = true
    
    private let tokenKey = "com.moodlift.authToken"
    
    private init() {
        Task { await checkAuth() }
    }
    
    func checkAuth() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let token = KeychainHelper.get(key: tokenKey) else {
            isAuthenticated = false
            return
        }
        
        await APIService.shared.setToken(token)
        
        do {
            let user: User = try await APIService.shared.request(endpoint: "/auth/profile")
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            KeychainHelper.delete(key: tokenKey)
            await APIService.shared.setToken(nil)
            await MainActor.run {
                self.isAuthenticated = false
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        struct LoginBody: Codable {
            let email: String
            let password: String
        }
        
        let response: AuthResponse = try await APIService.shared.request(
            endpoint: "/auth/login",
            method: "POST",
            body: LoginBody(email: email, password: password)
        )
        
        KeychainHelper.save(key: tokenKey, value: response.token)
        await APIService.shared.setToken(response.token)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
    }
    
    func register(email: String, username: String, password: String) async throws {
        struct RegisterBody: Codable {
            let email: String
            let username: String
            let password: String
        }
        
        let response: AuthResponse = try await APIService.shared.request(
            endpoint: "/auth/register",
            method: "POST",
            body: RegisterBody(email: email, username: username, password: password)
        )
        
        KeychainHelper.save(key: tokenKey, value: response.token)
        await APIService.shared.setToken(response.token)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
    }
    
    func logout() async {
        KeychainHelper.delete(key: tokenKey)
        await APIService.shared.setToken(nil)
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    func refreshProfile() async {
        do {
            let user: User = try await APIService.shared.request(endpoint: "/auth/profile")
            await MainActor.run {
                self.currentUser = user
            }
        } catch {
            // Silently fail
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        struct ChangePasswordBody: Codable {
            let currentPassword: String
            let newPassword: String
        }
        
        let _: EmptyResponse = try await APIService.shared.request(
            endpoint: "/auth/change-password",
            method: "POST",
            body: ChangePasswordBody(currentPassword: currentPassword, newPassword: newPassword)
        )
    }
}
