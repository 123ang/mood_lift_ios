import SwiftUI

struct MyContentView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel = ProfileViewModel()
    @State private var selectedItem: ContentItem?
    @State private var itemToRemove: ContentItem?
    @State private var showRemoveAlert = false
    private let mySubmittedStore = MySubmittedContentStore.shared

    var body: some View {
        let palette = themeManager.currentPalette
        VStack(spacing: 0) {
            headerSection(palette: palette)
            if viewModel.isLoadingMyContent && viewModel.myContent.isEmpty {
                Spacer()
                ProgressView()
                    .tint(palette.brandTint)
                Text("Loading your content...")
                    .font(.themeCallout())
                    .foregroundStyle(palette.mutedText)
                    .padding(.top, Theme.spaceM)
                Spacer()
            } else if viewModel.myContent.isEmpty {
                Spacer()
                emptyState(palette: palette)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: Theme.spaceM) {
                        ForEach(viewModel.myContent) { item in
                            MyContentRow(item: item, palette: palette, onTap: { selectedItem = item }, onRemove: {
                                itemToRemove = item
                                showRemoveAlert = true
                            })
                        }
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.top, Theme.spaceM)
                    .padding(.bottom, Theme.spaceXXL)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(palette.background)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadMyContent() }
        .refreshable { await viewModel.loadMyContent() }
        .sheet(item: $selectedItem) { item in
            MyContentDetailSheet(item: item)
        }
        .alert("Remove from My Content?", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {
                itemToRemove = nil
            }
            Button("Remove", role: .destructive) {
                if let item = itemToRemove {
                    mySubmittedStore.remove(contentId: item.id, userId: AuthService.shared.currentUser?.id)
                    Task { await viewModel.loadMyContent() }
                }
                itemToRemove = nil
            }
        } message: {
            Text("This will remove the post from your list. It may still appear in the feed if it was published.")
        }
    }

    private func headerSection(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Theme.spaceM) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                Text("My Content")
                    .font(.themeTitle())
                    .foregroundStyle(.white)
                Spacer()
            }
            Text(headerSubtitle)
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

    private var headerSubtitle: String {
        let count = viewModel.myContent.count
        let total = viewModel.totalLikesReceived
        if count == 0 { return "Posts you've shared" }
        if count == 1 {
            return total == 1 ? "1 post · 1 like" : "1 post · \(total) likes"
        }
        return "\(count) posts · \(total) likes"
    }

    private func emptyState(palette: ThemePalette) -> some View {
        VStack(spacing: Theme.spaceM) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(palette.mutedText)
            Text("No posts yet")
                .font(.themeHeadline())
                .foregroundStyle(palette.text)
            Text("Share encouragement, jokes, or fun facts from the Feeds tab and they'll show here with your like count.")
                .font(.themeCaption())
                .foregroundStyle(palette.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spaceXL)
        }
    }
}

// MARK: - Row: preview + likes, tappable + remove
private struct MyContentRow: View {
    let item: ContentItem
    var palette: ThemePalette
    let onTap: () -> Void
    let onRemove: () -> Void

    private var categoryColor: Color {
        (ContentCategory(rawValue: item.category) ?? .encouragement).color
    }

    private var categoryName: String {
        (ContentCategory(rawValue: item.category) ?? .encouragement).displayName
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spaceS) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: Theme.spaceM) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .fill(categoryColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "text.quote")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(categoryColor)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayText)
                            .font(.themeCallout())
                            .foregroundStyle(palette.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: Theme.spaceS) {
                            Text(categoryName)
                                .font(.themeCaptionMedium())
                                .foregroundStyle(categoryColor)
                            if let date = item.createdAt {
                                Text("·")
                                    .foregroundStyle(palette.mutedText)
                                Text(date.formatted(.relative(presentation: .named)))
                                    .font(.themeCaption())
                                    .foregroundStyle(palette.mutedText)
                            }
                        }
                    }
                    Spacer(minLength: Theme.spaceS)
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(categoryColor)
                            Text("\(item.score)")
                                .font(.themeHeadline())
                                .foregroundStyle(palette.text)
                        }
                        Text("likes")
                            .font(.themeCaption())
                            .foregroundStyle(palette.mutedText)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.mutedText)
                }
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.errorSoft)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.spaceM)
        .background(palette.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
    }
}

// MARK: - Sheet: full content read-only (same shape as feed card)
private struct MyContentDetailSheet: View {
    let item: ContentItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    private var categoryColor: Color {
        (ContentCategory(rawValue: item.category) ?? .encouragement).color
    }

    private var categoryName: String {
        (ContentCategory(rawValue: item.category) ?? .encouragement).displayName
    }

    var body: some View {
        let palette = themeManager.currentPalette
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.spaceL) {
                    HStack(spacing: Theme.spaceM) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.25))
                                .frame(width: 44, height: 44)
                            Text(categoryName.prefix(1))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(categoryColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(categoryName)
                                .font(.themeSubheadline())
                                .foregroundStyle(palette.text)
                            if let date = item.createdAt {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.themeCaption())
                                    .foregroundStyle(palette.mutedText)
                            }
                        }
                        Spacer()
                    }

                    Text(item.displayText)
                        .font(.themeBody())
                        .foregroundStyle(palette.text)
                        .multilineTextAlignment(.leading)
                    if let answer = item.answer, !answer.isEmpty, item.contentType == "qa" {
                        Text(answer)
                            .font(.themeCallout())
                            .foregroundStyle(palette.mutedText)
                            .italic()
                    }

                    HStack(spacing: Theme.spaceL) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundStyle(categoryColor)
                            Text("\(item.upvotes) upvotes")
                                .font(.themeCaption())
                                .foregroundStyle(palette.mutedText)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .foregroundStyle(palette.mutedText)
                            Text("\(item.downvotes) downvotes")
                                .font(.themeCaption())
                                .foregroundStyle(palette.mutedText)
                        }
                        Spacer()
                        Text("Net: \(item.score) likes")
                            .font(.themeCaptionMedium())
                            .foregroundStyle(categoryColor)
                    }
                    .padding(.top, Theme.spaceS)
                }
                .padding(Theme.spaceL)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
                .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
                .padding(.horizontal, Theme.spaceM)
            }
            .background(palette.background)
            .navigationTitle("Your post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.themeHeadline())
                        .foregroundStyle(palette.brandTint)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyContentView()
    }
}
