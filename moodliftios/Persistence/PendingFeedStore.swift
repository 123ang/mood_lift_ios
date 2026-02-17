import Foundation
import SwiftUI

/// Holds recently submitted posts so they show in Feeds immediately before the backend includes them (e.g. pending review).
@Observable
final class PendingFeedStore {
    static let shared = PendingFeedStore()

    private(set) var items: [ContentItem] = []

    func addPending(_ item: ContentItem) {
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.insert(item, at: 0)
    }

    func removeIds(_ ids: Set<String>) {
        items.removeAll { ids.contains($0.id) }
    }
}
