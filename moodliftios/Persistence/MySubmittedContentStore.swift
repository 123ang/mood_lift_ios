import Foundation
import SwiftUI

/// Persists content the current user has submitted so it always appears in Feeds and My Content, even if the backend doesn't return it (e.g. pending review or empty feed).
@Observable
final class MySubmittedContentStore {
    static let shared = MySubmittedContentStore()

    private let defaults = UserDefaults.standard
    private let keyPrefix = "moodlift_my_submitted_content_"

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var storage: [String: [ContentItem]] = [:]

    init() {
        loadAll()
    }

    /// Items submitted by the given user (current user id). Sorted newest first. Never removed — we only add/update.
    func items(userId: String?) -> [ContentItem] {
        guard let userId = userId else { return [] }
        return (storage[userId] ?? []).sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    /// Add or update a submission. Call this after successful submit so it always stays in feed and my content.
    func add(_ item: ContentItem, submittedByUserId: String?) {
        guard let userId = submittedByUserId else { return }
        var list = storage[userId] ?? []
        if let idx = list.firstIndex(where: { $0.id == item.id }) {
            list[idx] = item
        } else {
            list.insert(item, at: 0)
        }
        storage[userId] = list
        save(userId: userId)
    }

    /// Remove a submission from the current user's list (e.g. "Remove" in My Content). Persists immediately.
    func remove(contentId: String, userId: String?) {
        guard let userId = userId else { return }
        var list = storage[userId] ?? []
        list.removeAll { $0.id == contentId }
        storage[userId] = list
        save(userId: userId)
    }

    private func key(userId: String) -> String {
        keyPrefix + userId
    }

    private func loadAll() {
        if let userId = AuthService.shared.currentUser?.id {
            load(userId: userId)
        }
    }

    private func load(userId: String) {
        guard let data = defaults.data(forKey: key(userId: userId)),
              let decoded = try? Self.decoder.decode([ContentItem].self, from: data) else {
            return
        }
        storage[userId] = decoded
    }

    private func save(userId: String) {
        guard let list = storage[userId],
              let data = try? Self.encoder.encode(list) else { return }
        defaults.set(data, forKey: key(userId: userId))
    }

    /// Call after login so we load this user's stored submissions.
    func reloadForCurrentUser() {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        load(userId: userId)
    }
}
