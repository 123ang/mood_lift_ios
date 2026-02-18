import SwiftUI

// MARK: - Theme palette (tokens for theming)

struct ThemePalette {
    let primary: Color
    let primaryGradientStart: Color
    let primaryGradientEnd: Color
    let background: Color
    let card: Color
    let text: Color
    let mutedText: Color
    let border: Color
    let accent: Color
    /// For section headers, buttons, links
    let brandTint: Color

    /// Mini preview colors for theme picker (3–5 chips)
    var previewColors: [Color] {
        [primary, accent, card, text.opacity(0.6), border]
    }
}

// MARK: - Theme definition (id, name, palette, free vs locked)

struct ThemeDefinition: Identifiable {
    let id: String
    let name: String
    let palette: ThemePalette
    let isFree: Bool
}

// MARK: - All themes (5+ selectable, some locked)

enum ThemeDefinitions {
    static let defaultId = "default"

    static let all: [ThemeDefinition] = [
        ThemeDefinition(
            id: "default",
            name: "Default",
            palette: ThemePalette(
                primary: Color(hex: "#f4a898"),
                primaryGradientStart: Color(hex: "#f4a898"),
                primaryGradientEnd: Color(hex: "#f2c4b3"),
                background: Color(hex: "#faf6f4"),
                card: Color(hex: "#fefcfb"),
                text: Color(hex: "#4a4543"),
                mutedText: Color(hex: "#7a7573"),
                border: Color(hex: "#d4cfcc"),
                accent: Color(hex: "#f5e6b8"),
                brandTint: Color(hex: "#e8a598")
            ),
            isFree: true
        ),
        ThemeDefinition(
            id: "ocean",
            name: "Ocean Blue",
            palette: ThemePalette(
                primary: Color(hex: "#5b9bd5"),
                primaryGradientStart: Color(hex: "#5b9bd5"),
                primaryGradientEnd: Color(hex: "#7eb8e8"),
                background: Color(hex: "#f0f7fc"),
                card: Color(hex: "#f8fbfe"),
                text: Color(hex: "#2c3e50"),
                mutedText: Color(hex: "#5d6d7e"),
                border: Color(hex: "#b8d4e8"),
                accent: Color(hex: "#a8d4e6"),
                brandTint: Color(hex: "#5b9bd5")
            ),
            isFree: true
        ),
        ThemeDefinition(
            id: "midnight",
            name: "Midnight",
            palette: ThemePalette(
                primary: Color(hex: "#6c7bd8"),
                primaryGradientStart: Color(hex: "#4a5568"),
                primaryGradientEnd: Color(hex: "#2d3748"),
                background: Color(hex: "#1a202c"),
                card: Color(hex: "#2d3748"),
                text: Color(hex: "#e2e8f0"),
                mutedText: Color(hex: "#a0aec0"),
                border: Color(hex: "#4a5568"),
                accent: Color(hex: "#9f7aea"),
                brandTint: Color(hex: "#6c7bd8")
            ),
            isFree: false
        ),
        ThemeDefinition(
            id: "sakura",
            name: "Sakura Pink",
            palette: ThemePalette(
                primary: Color(hex: "#e8b4bc"),
                primaryGradientStart: Color(hex: "#e8b4bc"),
                primaryGradientEnd: Color(hex: "#f5d0d6"),
                background: Color(hex: "#fdf5f6"),
                card: Color(hex: "#fefafb"),
                text: Color(hex: "#4a3f41"),
                mutedText: Color(hex: "#8b7d80"),
                border: Color(hex: "#e8d4d8"),
                accent: Color(hex: "#f5c6d0"),
                brandTint: Color(hex: "#d48a96")
            ),
            isFree: false
        ),
        ThemeDefinition(
            id: "forest",
            name: "Forest Green",
            palette: ThemePalette(
                primary: Color(hex: "#68a67a"),
                primaryGradientStart: Color(hex: "#68a67a"),
                primaryGradientEnd: Color(hex: "#8bc49a"),
                background: Color(hex: "#f4f9f5"),
                card: Color(hex: "#fafcfb"),
                text: Color(hex: "#2d3d32"),
                mutedText: Color(hex: "#5c6b61"),
                border: Color(hex: "#b8d4c0"),
                accent: Color(hex: "#b8e0d0"),
                brandTint: Color(hex: "#5a9a6c")
            ),
            isFree: false
        ),
        ThemeDefinition(
            id: "sunset",
            name: "Sunset",
            palette: ThemePalette(
                primary: Color(hex: "#e07c5a"),
                primaryGradientStart: Color(hex: "#e07c5a"),
                primaryGradientEnd: Color(hex: "#f4a574"),
                background: Color(hex: "#fdf8f4"),
                card: Color(hex: "#fefaf7"),
                text: Color(hex: "#4a4039"),
                mutedText: Color(hex: "#7a6d65"),
                border: Color(hex: "#e8d4c8"),
                accent: Color(hex: "#f5e6b8"),
                brandTint: Color(hex: "#d46a48")
            ),
            isFree: false
        ),
        ThemeDefinition(
            id: "lavender",
            name: "Lavender",
            palette: ThemePalette(
                primary: Color(hex: "#9b8bb8"),
                primaryGradientStart: Color(hex: "#9b8bb8"),
                primaryGradientEnd: Color(hex: "#b5a8cc"),
                background: Color(hex: "#f8f6fb"),
                card: Color(hex: "#fcfbfd"),
                text: Color(hex: "#3d3848"),
                mutedText: Color(hex: "#6d6578"),
                border: Color(hex: "#d8d0e4"),
                accent: Color(hex: "#c4b8d8"),
                brandTint: Color(hex: "#8b7aa8")
            ),
            isFree: false
        )
    ]

    static func theme(id: String) -> ThemeDefinition? {
        all.first { $0.id == id }
    }

    static var defaultTheme: ThemeDefinition {
        theme(id: defaultId) ?? all[0]
    }
}
