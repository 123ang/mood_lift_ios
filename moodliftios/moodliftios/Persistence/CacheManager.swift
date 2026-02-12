import Foundation

class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("MoodLiftCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Content Caching
    
    func cacheContent(_ items: [ContentItem], category: String) {
        let key = "content_\(category)"
        saveToCache(items, key: key)
    }
    
    func getCachedContent(category: String) -> [ContentItem]? {
        let key = "content_\(category)"
        return loadFromCache(key: key)
    }
    
    func cacheDailyContent(_ items: [DailyContentItem], category: String) {
        let key = "daily_\(category)_\(todayString())"
        saveToCache(items, key: key)
    }
    
    func getCachedDailyContent(category: String) -> [DailyContentItem]? {
        let key = "daily_\(category)_\(todayString())"
        return loadFromCache(key: key)
    }
    
    func cacheSavedItems(_ items: [SavedItem]) {
        saveToCache(items, key: "saved_items")
    }
    
    func getCachedSavedItems() -> [SavedItem]? {
        return loadFromCache(key: "saved_items")
    }
    
    func cacheUserProfile(_ user: User) {
        saveToCache(user, key: "user_profile")
    }
    
    func getCachedUserProfile() -> User? {
        return loadFromCache(key: "user_profile")
    }
    
    func cacheCheckinInfo(_ info: CheckinInfo) {
        saveToCache(info, key: "checkin_info")
    }
    
    func getCachedCheckinInfo() -> CheckinInfo? {
        return loadFromCache(key: "checkin_info")
    }
    
    // MARK: - Generic Cache Operations
    
    private func saveToCache<T: Encodable>(_ object: T, key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url)
        } catch {
            print("Cache save error for \(key): \(error)")
        }
    }
    
    private func loadFromCache<T: Decodable>(key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
