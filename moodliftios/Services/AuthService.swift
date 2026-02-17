import Foundation
import Security

@Observable
class AuthService {
    static let shared = AuthService()
    
    var currentUser: User?
    var isAuthenticated: Bool = false
    var isLoading: Bool = true
    /// When stats API returns a higher balance than profile (e.g. after check-in), use it so all screens show the same points.
    private(set) var lastKnownStatsBalance: Int?

    /// Single source for points shown everywhere. Uses the higher of profile balance or stats balance so Profile, Home, and Content detail stay in sync (e.g. 6 after check-in).
    var displayPoints: Int {
        let authBalance: Int = {
            guard let u = currentUser else { return 0 }
            return min(u.points, u.pointsBalance)
        }()
        return max(authBalance, lastKnownStatsBalance ?? 0)
    }
    
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
            let data = try await APIService.shared.requestData(endpoint: "/auth/profile")
            let user = try APIDecoder.decode(User.self, from: data)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                MySubmittedContentStore.shared.reloadForCurrentUser()
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
        
        let data = try await APIService.shared.requestData(
            endpoint: "/auth/login",
            method: "POST",
            body: LoginBody(email: email, password: password)
        )
        let response = try APIDecoder.decode(AuthResponse.self, from: data)
        
        KeychainHelper.save(key: tokenKey, value: response.token)
        await APIService.shared.setToken(response.token)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
            MySubmittedContentStore.shared.reloadForCurrentUser()
        }
    }
    
    func register(email: String, username: String, password: String) async throws {
        struct RegisterBody: Codable {
            let email: String
            let username: String
            let password: String
        }
        
        let data = try await APIService.shared.requestData(
            endpoint: "/auth/register",
            method: "POST",
            body: RegisterBody(email: email, username: username, password: password)
        )
        let response = try APIDecoder.decode(AuthResponse.self, from: data)
        
        KeychainHelper.save(key: tokenKey, value: response.token)
        await APIService.shared.setToken(response.token)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
            MySubmittedContentStore.shared.reloadForCurrentUser()
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
            let data = try await APIService.shared.requestData(endpoint: "/auth/profile")
            let user = try APIDecoder.decode(User.self, from: data)
            var statsBalance: Int?
            if let stats = try? await PointsService.shared.getUserStats() {
                statsBalance = stats.pointsBalance
            }
            await MainActor.run {
                self.currentUser = user
                self.lastKnownStatsBalance = statsBalance
            }
        } catch {
            // Silently fail
        }
    }

    /// Call when you have fresh stats so displayPoints stays in sync (e.g. when Profile loads).
    func setLastKnownStatsBalance(_ value: Int?) {
        lastKnownStatsBalance = value
    }

    /// Update current user's balance from check-in response so "Points" reflects the new total (e.g. 5 + 1 = 6).
    func updateBalanceFromCheckin(totalPoints: Int) async {
        await MainActor.run {
            guard var u = currentUser else { return }
            u.points = totalPoints
            u.pointsBalance = totalPoints
            currentUser = u
        }
    }

    /// Add points locally when user submits content (backend should also award and record the transaction).
    func addPointsForSubmission(_ amount: Int) async {
        await MainActor.run {
            guard amount > 0, var u = currentUser else { return }
            u.points += amount
            u.pointsBalance += amount
            currentUser = u
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        struct ChangePasswordBody: Codable {
            let currentPassword: String
            let newPassword: String
        }
        
        let data = try await APIService.shared.requestData(
            endpoint: "/auth/change-password",
            method: "POST",
            body: ChangePasswordBody(currentPassword: currentPassword, newPassword: newPassword)
        )
        _ = try APIDecoder.decode(EmptyResponse.self, from: data)
    }
}
