import SwiftUI

/// Manages current theme and unlocked themes. Persists to UserDefaults.
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let defaults = UserDefaults.standard
    private let selectedKey = "moodlift_selected_theme_id"
    private let unlockedKey = "moodlift_unlocked_theme_ids"

    var currentThemeId: String {
        didSet {
            defaults.set(currentThemeId, forKey: selectedKey)
        }
    }

    var unlockedThemeIds: Set<String> {
        didSet {
            let array = Array(unlockedThemeIds)
            defaults.set(array, forKey: unlockedKey)
        }
    }

    init() {
        self.currentThemeId = defaults.string(forKey: selectedKey) ?? ThemeDefinitions.defaultId
        let stored = defaults.array(forKey: unlockedKey) as? [String] ?? []
        self.unlockedThemeIds = Set(stored)
    }

    /// Palette for the currently selected theme (for live preview).
    var currentPalette: ThemePalette {
        ThemeDefinitions.theme(id: currentThemeId)?.palette ?? ThemeDefinitions.defaultTheme.palette
    }

    /// Currently selected theme definition.
    var currentTheme: ThemeDefinition {
        ThemeDefinitions.theme(id: currentThemeId) ?? ThemeDefinitions.defaultTheme
    }

    func setTheme(_ themeId: String) {
        guard isUnlocked(themeId), ThemeDefinitions.theme(id: themeId) != nil else { return }
        currentThemeId = themeId
    }

    func unlockTheme(_ themeId: String) {
        unlockedThemeIds.insert(themeId)
    }

    func isUnlocked(_ themeId: String) -> Bool {
        ThemeDefinitions.theme(id: themeId)?.isFree == true || unlockedThemeIds.contains(themeId)
    }
}

// MARK: - Environment

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager = .shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
