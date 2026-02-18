import SwiftUI

// MARK: - SoftCard — Slightly tinted pastel surface, large radius, soft shadow. No harsh borders.
struct SoftCard<Content: View>: View {
    var backgroundColor: Color = Color.cardBackground
    var cornerRadius: CGFloat = Theme.radiusLarge
    var padding: CGFloat = Theme.spaceL
    var useShadow: Bool = true
    var elevatedShadow: Bool = false
    var borderColor: Color? = nil
    var contentAlignment: Alignment = .leading
    @ViewBuilder let content: () -> Content

    private var shadowColor: Color {
        guard useShadow else { return .clear }
        return elevatedShadow ? Theme.elevatedCardShadow().color : Theme.cardShadow().color
    }
    private var shadowRadius: CGFloat {
        elevatedShadow ? Theme.elevatedCardShadow().radius : Theme.cardShadow().radius
    }
    private var shadowY: CGFloat {
        elevatedShadow ? Theme.elevatedCardShadow().y : Theme.cardShadow().y
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: contentAlignment)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(borderColor ?? .clear, lineWidth: borderColor != nil ? 1 : 0)
                    )
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            )
    }
}

// MARK: - MoodButton — Primary action: soft gradient, rounded, gentle
struct MoodButton: View {
    let title: String
    var icon: String? = nil
    var style: MoodButtonStyle = .primary
    let action: () -> Void

    enum MoodButtonStyle {
        case primary
        case secondary(tint: Color)
        case success
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spaceS) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                Text(title)
                    .font(.themeHeadline())
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spaceM)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: shadowColor, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .success: return .white
        case .secondary: return Color.darkText
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary(let tint):
            tint.opacity(0.15)
        case .success:
            Color.successSoft
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.primarySoft.opacity(0.25)
        case .secondary, .success:
            return Color.black.opacity(0.05)
        }
    }
}

// MARK: - SectionHeader — Welcoming, not technical
struct SectionHeader: View {
    var icon: String? = nil
    let title: String
    var subtitle: String? = nil
    var tint: Color = Color.brandPrimary
    var textColor: Color = Color.darkText
    var subtitleColor: Color = Color.lightText

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXS) {
            HStack(spacing: Theme.spaceS) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.themeHeadline())
                    .foregroundStyle(textColor)
            }
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.themeCaption())
                    .foregroundStyle(subtitleColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Theme.spaceS)
    }
}

// MARK: - CategoryBubble — Clear, readable filter chips (good contrast when unselected)
struct CategoryBubble: View {
    let label: String
    var icon: String? = nil
    var imageAssetName: String? = nil
    let color: Color
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let asset = imageAssetName {
                    Image(asset)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.medium))
                }
                Text(label)
                    .font(.themeCaptionMedium())
            }
            .foregroundStyle(isSelected ? .white : Color.darkText)
            .padding(.horizontal, Theme.spaceM)
            .padding(.vertical, Theme.spaceS + 2)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : color.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CategorySelector — Icon-based segments: selected = filled pill, unselected = icon only.
struct CategorySelector: View {
    @Binding var selectedCategory: String?
    /// (id, accessibilityLabel, imageAssetName). Use nil imageAssetName for "All" (shows grid icon).
    var options: [(id: String?, label: String, imageAssetName: String?)]
    var colorForId: (String?) -> Color
    var animation: Animation = .easeInOut(duration: 0.25)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spaceS) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    CategorySelectorSegment(
                        label: option.label,
                        imageAssetName: option.imageAssetName,
                        isAll: option.id == nil,
                        isSelected: selectedCategory == option.id,
                        color: colorForId(option.id)
                    ) {
                        withAnimation(animation) {
                            selectedCategory = option.id
                        }
                    }
                }
            }
            .padding(.leading, Theme.spaceM)
            .padding(.trailing, Theme.spaceM)
            .padding(.vertical, Theme.spaceS)
        }
    }
}

private struct CategorySelectorSegment: View {
    let label: String
    let imageAssetName: String?
    let isAll: Bool
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    private let iconSize: CGFloat = 24

    var body: some View {
        Button(action: action) {
            segmentContent
                .foregroundStyle(segmentForeground)
                .frame(width: 44, height: 44)
                .background(Circle().fill(segmentBackground))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var segmentContent: some View {
        if isAll {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: iconSize - 4, weight: .medium))
        } else if let name = imageAssetName {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize - 2, height: iconSize - 2)
        } else {
            Image(systemName: "circle.grid.2x2.fill")
                .font(.system(size: iconSize - 4, weight: .medium))
        }
    }

    private var segmentForeground: Color {
        if isSelected {
            return isAll ? Color.darkText : .white
        }
        return color.opacity(isAll ? 0.6 : 0.85)
    }

    private var segmentBackground: Color {
        guard isSelected else { return .clear }
        return isAll ? Color.mutedText.opacity(0.3) : color
    }
}
