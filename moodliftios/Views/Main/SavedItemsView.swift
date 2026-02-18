import SwiftUI

struct SavedItemsView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel = SavedItemsViewModel()
    @State private var itemToDelete: SavedItem?
    @State private var showDeleteAlert = false

    private var categoryChipOptions: [(id: String?, label: String, imageAssetName: String?)] {
        [(nil, "All", nil)] + ContentCategory.allCases.map { ($0.rawValue, $0.displayName, $0.imageAssetName) }
    }

    var body: some View {
        let palette = themeManager.currentPalette
        VStack(spacing: 0) {
            headerSection(palette: palette)
            categorySelectorSection(palette: palette)
            contentSection(palette: palette)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(palette.background)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadSavedItems() }
        .refreshable { await viewModel.loadSavedItems() }
        .alert("Remove from saved?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let item = itemToDelete {
                    Task { await viewModel.removeItem(contentId: item.contentId) }
                }
            }
        } message: {
            Text("You can always save it again later.")
        }
    }

    // MARK: - Header (colored bar like Settings/Preferences; separates top from content)
    private func headerSection(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Theme.spaceM) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                Text("Saved Items")
                    .font(.themeTitle())
                    .foregroundStyle(.white)
                Spacer()
            }
            Text(savedSubtitle)
                .font(.themeCallout())
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.spaceM)
        .padding(.vertical, Theme.spaceL)
        .background(
            LinearGradient(
                colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var savedSubtitle: String {
        let count = viewModel.savedItems.count
        if count == 0 { return "Your collection" }
        return count == 1 ? "1 saved" : "\(count) saved"
    }

    // MARK: - Category selector (icons only; selected = filled, unselected = outline)
    private func categorySelectorSection(palette: ThemePalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spaceS) {
                ForEach(Array(categoryChipOptions.enumerated()), id: \.offset) { _, option in
                    SavedCategoryChip(
                        label: option.label,
                        imageAssetName: option.imageAssetName,
                        isAll: option.id == nil,
                        isSelected: viewModel.selectedCategory == option.id,
                        color: chipColor(for: option.id),
                        palette: palette
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.filterByCategory(option.id)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.spaceM)
            .padding(.vertical, Theme.spaceM)
        }
        .padding(.bottom, Theme.spaceS)
        .background(palette.background)
    }

    private func chipColor(for id: String?) -> Color {
        guard let id = id, let cat = ContentCategory(rawValue: id) else { return Color.mutedText }
        return cat.color
    }

    // MARK: - Content (fills remaining height so whole page is used)
    private func contentSection(palette: ThemePalette) -> some View {
        Group {
            if viewModel.isLoading {
                loadingState(palette: palette)
            } else if viewModel.filteredItems.isEmpty {
                emptyState(palette: palette)
            } else {
                savedItemsList(palette: palette)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedCategory)
        .transition(.opacity.combined(with: .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )))
    }

    private func savedItemsList(palette: ThemePalette) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Theme.spaceM) {
                ForEach(viewModel.filteredItems) { item in
                    SavedItemCard(item: item, palette: palette) {
                        itemToDelete = item
                        showDeleteAlert = true
                    }
                }
            }
            .padding(.horizontal, Theme.spaceM)
            .padding(.top, Theme.spaceM)
            .padding(.bottom, Theme.spaceL)
        }
    }

    private func loadingState(palette: ThemePalette) -> some View {
        VStack(spacing: Theme.spaceM) {
            Spacer()
            ProgressView()
                .scaleEffect(1.1)
                .tint(palette.brandTint)
            Text("Loading your collection...")
                .font(.themeCallout())
                .foregroundStyle(palette.mutedText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty state (closer to selector; warm, browsing-memories tone)
    private func emptyState(palette: ThemePalette) -> some View {
        VStack(spacing: Theme.spaceM) {
            Spacer(minLength: 0)
            Image(systemName: "heart.text.square")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(palette.brandTint.opacity(0.5))
            Text(viewModel.selectedCategory != nil ? "Nothing here yet" : "Your collection is empty")
                .font(.themeHeadline())
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.center)
            Text(viewModel.selectedCategory != nil
                 ? "Save something from this category and it’ll show up here."
                 : "Save content you love and it'll appear here.")
                .font(.themeCallout())
                .foregroundStyle(palette.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spaceL)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Category chip (icon only; selected = filled, unselected = outline)
private struct SavedCategoryChip: View {
    let label: String
    let imageAssetName: String?
    let isAll: Bool
    let isSelected: Bool
    let color: Color
    var palette: ThemePalette
    let action: () -> Void

    private let iconSize: CGFloat = 30

    var body: some View {
        Button(action: action) {
            chipIcon
                .foregroundStyle(isSelected ? (isAll ? palette.text : .white) : color.opacity(0.9))
                .frame(width: 54, height: 54)
                .background(Circle().fill(chipBackground))
                .overlay(Circle().strokeBorder(color.opacity(isSelected ? 0 : 0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var chipIcon: some View {
        if isAll {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: iconSize - 4, weight: .medium))
        } else if let name = imageAssetName {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(systemName: "circle.grid.2x2.fill")
                .font(.system(size: iconSize - 4, weight: .medium))
        }
    }

    private var chipBackground: Color {
        guard isSelected else { return .clear }
        return isAll ? palette.mutedText.opacity(0.25) : color
    }
}

// MARK: - Saved Item Card (soft fill, no thick borders; content-first hierarchy)
private struct SavedItemCard: View {
    let item: SavedItem
    var palette: ThemePalette
    let onDelete: () -> Void

    private var categoryEnum: ContentCategory? { ContentCategory(rawValue: item.category) }
    private var categoryColor: Color { categoryEnum?.color ?? .brandPrimary }
    private var categoryLightColor: Color { categoryEnum?.lightColor ?? Color.primarySoftLight }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM) {
            // Subtle category (same palette, low emphasis)
            if let cat = categoryEnum {
                Text(cat.displayName)
                    .font(.themeCaption())
                    .foregroundStyle(categoryColor.opacity(0.85))
            }
            // Primary: saved content text
            Text(item.displayText)
                .font(.themeBodyMedium())
                .foregroundStyle(palette.text)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)

            if item.contentType == "quiz" { quizOptionsView(palette: palette) }
            if item.contentType == "qa", let answer = item.answer {
                HStack(alignment: .top, spacing: 6) {
                    Text("A:")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(Color.successSoft)
                    Text(answer)
                        .font(.themeCaption())
                        .foregroundStyle(palette.mutedText)
                        .lineLimit(3)
                }
                .padding(Theme.spaceS)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.successSoftBg)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
            }

            // Secondary / tertiary + delete (low emphasis)
            HStack(spacing: Theme.spaceS) {
                if let author = item.author, !author.isEmpty {
                    Text(author)
                        .font(.themeCaption())
                        .foregroundStyle(palette.mutedText)
                }
                if let savedAt = item.savedAt {
                    Text(savedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.themeCaption())
                        .foregroundStyle(palette.mutedText)
                }
                Spacer(minLength: 0)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.errorSoft.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(Theme.spaceM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
    }

    @ViewBuilder
    private func quizOptionsView(palette: ThemePalette) -> some View {
        let options = [
            ("A", item.optionA), ("B", item.optionB), ("C", item.optionC), ("D", item.optionD)
        ].compactMap { label, value in value.map { (label, $0) } }
        VStack(alignment: .leading, spacing: 4) {
            ForEach(options, id: \.0) { label, value in
                HStack(spacing: 6) {
                    Text("\(label).")
                        .font(.themeCaptionMedium())
                        .foregroundStyle(label == item.correctOption ? Color.successSoft : palette.mutedText)
                    Text(value)
                        .font(.themeCaption())
                        .foregroundStyle(label == item.correctOption ? Color.successSoft : palette.mutedText)
                    if label == item.correctOption {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.successSoft)
                    }
                }
            }
        }
        .padding(Theme.spaceS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.factsGreenLight.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
    }
}

#Preview {
    NavigationStack {
        SavedItemsView()
    }
}
