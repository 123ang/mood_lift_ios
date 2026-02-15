import Foundation

@Observable
class SavedItemsViewModel {
    var savedItems: [SavedItem] = []
    var filteredItems: [SavedItem] = []
    var selectedCategory: String? = nil
    var isLoading = false
    var errorMessage: String?
    
    func loadSavedItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            savedItems = try await SavedService.shared.getSavedItems()
            CacheManager.shared.cacheSavedItems(savedItems)
            applyFilter()
        } catch {
            if let cached = CacheManager.shared.getCachedSavedItems() {
                savedItems = cached
                applyFilter()
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func filterByCategory(_ category: String?) {
        selectedCategory = category
        applyFilter()
    }
    
    private func applyFilter() {
        if let category = selectedCategory {
            filteredItems = savedItems.filter { $0.category == category }
        } else {
            filteredItems = savedItems
        }
    }
    
    func removeItem(contentId: String) async {
        do {
            try await SavedService.shared.unsaveItem(contentId: contentId)
            savedItems.removeAll { $0.contentId == contentId }
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
