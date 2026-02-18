import SwiftUI

struct ThemePickerView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @State private var themeToUnlock: ThemeDefinition?
    @State private var showUnlockDialog = false

    var body: some View {
        let palette = themeManager.currentPalette
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.spaceM) {
                    Text("Choose a theme. Locked themes can be unlocked.")
                        .font(.themeCaption())
                        .foregroundStyle(palette.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.spaceM)

                    ForEach(ThemeDefinitions.all) { theme in
                        themeRow(theme: theme, palette: palette)
                    }
                }
                .padding(.vertical, Theme.spaceL)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Change Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(palette.brandTint)
                }
            }
        }
        .alert("Unlock \(themeToUnlock?.name ?? "Theme")?", isPresented: $showUnlockDialog) {
            Button("Not now", role: .cancel) {
                themeToUnlock = nil
            }
            Button("Unlock") {
                if let theme = themeToUnlock {
                    themeManager.unlockTheme(theme.id)
                    themeManager.setTheme(theme.id)
                    themeToUnlock = nil
                }
            }
        } message: {
            Text("Unlock to use this theme.")
        }
    }

    private func themeRow(theme: ThemeDefinition, palette: ThemePalette) -> some View {
        let isUnlocked = themeManager.isUnlocked(theme.id)
        let isActive = themeManager.currentThemeId == theme.id

        return Button {
            if isUnlocked {
                themeManager.setTheme(theme.id)
            } else {
                themeToUnlock = theme
                showUnlockDialog = true
            }
        } label: {
            HStack(spacing: Theme.spaceM) {
                // Mini palette preview (3–5 circles)
                HStack(spacing: 6) {
                    ForEach(Array(theme.palette.previewColors.prefix(5).enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(palette.border.opacity(0.5), lineWidth: 1)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.name)
                        .font(.themeHeadline())
                        .foregroundStyle(palette.text)
                }

                Spacer()

                // Status badge
                if isActive {
                    Text("ACTIVE")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.spaceS)
                        .padding(.vertical, 4)
                        .background(palette.brandTint)
                        .clipShape(Capsule())
                } else if theme.isFree {
                    Text("FREE")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(palette.mutedText)
                        .padding(.horizontal, Theme.spaceS)
                        .padding(.vertical, 4)
                        .background(palette.border.opacity(0.3))
                        .clipShape(Capsule())
                } else if !isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Unlock")
                            .font(.themeCaptionMedium())
                    }
                    .foregroundStyle(palette.mutedText)
                    .padding(.horizontal, Theme.spaceS)
                    .padding(.vertical, 4)
                    .background(palette.border.opacity(0.25))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Theme.spaceM)
            .padding(.vertical, Theme.spaceM)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.spaceM)
    }
}

#Preview {
    ThemePickerView()
        .environment(\.themeManager, ThemeManager.shared)
}
