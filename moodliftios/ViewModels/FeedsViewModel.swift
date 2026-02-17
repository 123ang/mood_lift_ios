import Foundation
import SwiftUI

@Observable
final class FeedsViewModel {
    var feedItems: [ContentItem] = []
    var isLoading = false
    var errorMessage: String?
    var currentPage = 1
    private let pageSize = 20

    func loadFeed() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        defer { isLoading = false }
        do {
            feedItems = try await ContentService.shared.getFeedContent(page: 1, limit: pageSize)
            PendingFeedStore.shared.removeIds(Set(feedItems.map(\.id)))
        } catch {
            // Fallback: if backend has no /content/feed, try category lists with include_pending so submissions show
            do {
                var merged: [ContentItem] = []
                for category in ContentCategory.allCases {
                    let items = try await ContentService.shared.getContent(category: category.rawValue, page: 1, limit: 15, sort: "newest", includePending: true)
                    merged.append(contentsOf: items)
                }
                feedItems = merged.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
                PendingFeedStore.shared.removeIds(Set(feedItems.map(\.id)))
                if feedItems.isEmpty { errorMessage = error.localizedDescription }
            } catch _ {
                errorMessage = error.localizedDescription
                feedItems = []
            }
        }
    }

    func loadMoreIfNeeded(currentId: String) async {
        guard !isLoading, feedItems.count >= pageSize,
              let index = feedItems.firstIndex(where: { $0.id == currentId }),
              index >= feedItems.count - 3 else { return }
        await loadNextPage()
    }

    private func loadNextPage() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let next = currentPage + 1
            let more = try await ContentService.shared.getFeedContent(page: next, limit: pageSize)
            if more.isEmpty { return }
            currentPage = next
            feedItems.append(contentsOf: more)
        } catch {
            // Pagination fallback not implemented (would need per-category pagination); ignore
        }
    }

    func voteOnContent(contentId: String, voteType: String) async {
        do {
            let updated = try await ContentService.shared.voteOnContent(contentId: contentId, voteType: voteType)
            if let i = feedItems.firstIndex(where: { $0.id == contentId }) {
                feedItems[i] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
