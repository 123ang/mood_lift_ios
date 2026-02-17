import Foundation
import SwiftUI

@Observable
class ContentViewModel {
    var dailyContent: [DailyContentItem] = []
    var currentIndex = 0
    var isLoading = false
    var isUnlocking = false
    var errorMessage: String?
    var category: ContentCategory
    /// Content IDs the user has saved this session (for instant bookmark highlight).
    var savedContentIds: Set<String> = []
    
    init(category: ContentCategory) {
        self.category = category
    }
    
    var currentItem: DailyContentItem? {
        guard currentIndex < dailyContent.count else { return nil }
        return dailyContent[currentIndex]
    }
    
    func loadDailyContent() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let full = try await ContentService.shared.getDailyContent(category: category.rawValue)
            dailyContent = Array(full.prefix(Constants.maxDailyContentPerCategory))
            applyFirstItemFreePerDay()
            CacheManager.shared.cacheDailyContent(dailyContent, category: category.rawValue)
        } catch {
            // Try cache
            if let cached = CacheManager.shared.getCachedDailyContent(category: category.rawValue) {
                dailyContent = Array(cached.prefix(Constants.maxDailyContentPerCategory))
                applyFirstItemFreePerDay()
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// First item in each category is free to read once per day; no coins spent.
    private func applyFirstItemFreePerDay() {
        if !dailyContent.isEmpty {
            var first = dailyContent[0]
            first.isUnlocked = true
            dailyContent[0] = first
        }
    }

    func unlockContent(contentId: String) async {
        guard let index = dailyContent.firstIndex(where: { $0.contentId == contentId }) else { return }
        // First item per category is free (no API call, no coins spent).
        if index == 0 {
            var item = dailyContent[0]
            item.isUnlocked = true
            dailyContent[0] = item
            await AuthService.shared.refreshProfile()
            return
        }
        isUnlocking = true
        defer { isUnlocking = false }
        // Use latest balance from server before attempting unlock
        await AuthService.shared.refreshProfile()
        do {
            _ = try await ContentService.shared.unlockContent(contentId: contentId)
            var item = dailyContent[index]
            item.isUnlocked = true
            dailyContent[index] = item
            await AuthService.shared.refreshProfile()
        } catch {
            await AuthService.shared.refreshProfile()
            errorMessage = error.localizedDescription
        }
    }
    
    func voteOnContent(contentId: String, voteType: String) async {
        do {
            _ = try await ContentService.shared.voteOnContent(contentId: contentId, voteType: voteType)
            updateLocalVote(contentId: contentId, voteType: voteType)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateLocalVote(contentId: String, voteType: String) {
        guard let index = dailyContent.firstIndex(where: { $0.content?.id == contentId }),
              var content = dailyContent[index].content else { return }
        let previous = content.userVote
        content.userVote = voteType
        if previous == "up" { content.upvotes = max(0, content.upvotes - 1) }
        if previous == "down" { content.downvotes = max(0, content.downvotes - 1) }
        if voteType == "up" { content.upvotes += 1 }
        if voteType == "down" { content.downvotes += 1 }
        dailyContent[index].content = content
    }

    func saveContent(contentId: String) async {
        do {
            try await SavedService.shared.saveItem(contentId: contentId)
            savedContentIds.insert(contentId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func reportContent(contentId: String, reason: String) async {
        do {
            try await ContentService.shared.reportContent(contentId: contentId, reason: reason)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func goToNext() {
        if currentIndex < dailyContent.count - 1 {
            currentIndex += 1
        }
    }
    
    func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}
