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
            dailyContent = try await ContentService.shared.getDailyContent(category: category.rawValue)
            CacheManager.shared.cacheDailyContent(dailyContent, category: category.rawValue)
        } catch {
            // Try cache
            if let cached = CacheManager.shared.getCachedDailyContent(category: category.rawValue) {
                dailyContent = cached
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func unlockContent(contentId: String) async {
        isUnlocking = true
        defer { isUnlocking = false }
        
        do {
            let response = try await ContentService.shared.unlockContent(contentId: contentId)
            // Update local state
            if let index = dailyContent.firstIndex(where: { $0.contentId == contentId }) {
                dailyContent[index].isUnlocked = true
            }
            await AuthService.shared.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func voteOnContent(contentId: String, voteType: String) async {
        do {
            let updated = try await ContentService.shared.voteOnContent(contentId: contentId, voteType: voteType)
            // Update local state
            if let index = dailyContent.firstIndex(where: { $0.content?.id == contentId }) {
                // We'd need to update the nested content - simplified here
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func saveContent(contentId: String) async {
        do {
            try await SavedService.shared.saveItem(contentId: contentId)
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
