import Foundation

@Observable
class ProfileViewModel {
    var stats: UserStats?
    var recentTransactions: [PointsTransaction] = []
    var myContent: [ContentItem] = []
    var isLoading = false
    var isLoadingMyContent = false
    var errorMessage: String?

    /// Total likes received on the user's content (upvotes − downvotes per item, summed).
    var totalLikesReceived: Int {
        myContent.reduce(0) { $0 + $1.score }
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let statsTask = PointsService.shared.getUserStats()
            async let historyTask = PointsService.shared.getPointsHistory(page: 1, limit: 5)

            let (fetchedStats, history) = try await (statsTask, historyTask)
            stats = fetchedStats
            recentTransactions = history.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMyContent() async {
        isLoadingMyContent = true
        defer { isLoadingMyContent = false }
        let stored = MySubmittedContentStore.shared.items(userId: AuthService.shared.currentUser?.id)
        do {
            let fromApi = try await ContentService.shared.getMyContent(page: 1, limit: 50)
            var byId: [String: ContentItem] = [:]
            for item in stored { byId[item.id] = item }
            for item in fromApi { byId[item.id] = item }
            myContent = Array(byId.values).sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        } catch {
            myContent = stored
        }
    }
}
