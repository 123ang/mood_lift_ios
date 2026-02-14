import SwiftUI

struct SavedItemsView: View {
    @State private var viewModel = SavedItemsViewModel()
    @State private var itemToDelete: SavedItem?
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            filterBar

            if viewModel.isLoading {
                loadingState
            } else if viewModel.filteredItems.isEmpty {
                emptyState
            } else {
                savedItemsList
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSavedItems()
        }
        .refreshable {
            await viewModel.loadSavedItems()
        }
        .alert("Remove Saved Item", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let item = itemToDelete {
                    Task {
                        await viewModel.removeItem(contentId: item.contentId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove this item from your saved collection?")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [.primaryGradientStart, .primaryGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)

                Text("Saved Items")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(viewModel.savedItems.count) item\(viewModel.savedItems.count == 1 ? "" : "s") saved")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.vertical, 28)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(
                    label: "All",
                    icon: "square.grid.2x2.fill",
                    iconIsAsset: false,
                    color: .encouragementPink,
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.filterByCategory(nil)
                }

                ForEach(ContentCategory.allCases, id: \.self) { category in
                    FilterChip(
                        label: category.displayName,
                        icon: category.imageAssetName,
                        iconIsAsset: true,
                        color: category.color,
                        isSelected: viewModel.selectedCategory == category.rawValue
                    ) {
                        viewModel.filterByCategory(category.rawValue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(.white)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Saved Items List

    private var savedItemsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.filteredItems) { item in
                    SavedItemCard(item: item) {
                        itemToDelete = item
                        showDeleteAlert = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.1)
            Text("Loading saved items...")
                .font(.subheadline)
                .foregroundStyle(Color.lightText)
                .padding(.top, 12)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bookmark")
                .font(.system(size: 52))
                .foregroundStyle(Color.lightText.opacity(0.4))

            Text("No saved items yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.darkText)

            Text(viewModel.selectedCategory != nil
                 ? "No items saved in this category"
                 : "Bookmark content you love to find it here later!")
                .font(.subheadline)
                .foregroundStyle(Color.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let icon: String
    var iconIsAsset: Bool = false
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Group {
                    if iconIsAsset {
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: icon)
                            .font(.caption.weight(.semibold))
                    }
                }
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? .white : color)
            .background(isSelected ? color : color.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Saved Item Card

private struct SavedItemCard: View {
    let item: SavedItem
    let onDelete: () -> Void

    private var categoryEnum: ContentCategory? {
        ContentCategory(rawValue: item.category)
    }

    private var categoryColor: Color {
        categoryEnum?.color ?? .encouragementPink
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    if let cat = categoryEnum {
                        Image(cat.imageAssetName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text(cat.displayName)
                            .font(.caption2.weight(.semibold))
                    }

                    Text("\u{2022} \(item.contentType.capitalized)")
                        .font(.caption2)
                        .foregroundStyle(Color.lightText)
                }
                .foregroundStyle(categoryColor)

                Text(item.displayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.darkText)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                if item.contentType == "quiz" {
                    quizOptionsView
                }

                if item.contentType == "qa", let answer = item.answer {
                    HStack(alignment: .top, spacing: 6) {
                        Text("A:")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.successGreen)
                        Text(answer)
                            .font(.caption)
                            .foregroundStyle(Color.lightText)
                            .lineLimit(3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.successGreen.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack {
                    if let author = item.author, !author.isEmpty {
                        Label(author, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(Color.lightText)
                    }

                    if let savedAt = item.savedAt {
                        Text(savedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color.lightText.opacity(0.7))
                    }

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(Color.errorRed.opacity(0.7))
                            .padding(8)
                            .background(Color.errorRed.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    @ViewBuilder
    private var quizOptionsView: some View {
        let options = [
            ("A", item.optionA),
            ("B", item.optionB),
            ("C", item.optionC),
            ("D", item.optionD)
        ].compactMap { label, value in
            value.map { (label, $0) }
        }

        VStack(alignment: .leading, spacing: 4) {
            ForEach(options, id: \.0) { label, value in
                HStack(spacing: 6) {
                    Text("\(label).")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(label == item.correctOption ? Color.successGreen : Color.lightText)
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(label == item.correctOption ? Color.successGreen : Color.lightText)

                    if label == item.correctOption {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.successGreen)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.factsGreen.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        SavedItemsView()
    }
}
