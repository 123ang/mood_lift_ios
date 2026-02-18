import SwiftUI

struct FeedsView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel = FeedsViewModel()
    private let pendingStore = PendingFeedStore.shared
    private let mySubmittedStore = MySubmittedContentStore.shared

    /// Feed from API + your persisted submissions (so your content always stays visible). Pending first, then merged by date; dedupe by id (prefer API).
    private var displayedItems: [ContentItem] {
        let feedItems = viewModel.feedItems
        let feedIds = Set(feedItems.map(\.id))
        let pendingOnly = pendingStore.items.filter { !feedIds.contains($0.id) }
        let myItems = mySubmittedStore.items(userId: AuthService.shared.currentUser?.id)
        var byId: [String: ContentItem] = [:]
        for item in myItems { byId[item.id] = item }
        for item in pendingOnly { byId[item.id] = item }
        for item in feedItems { byId[item.id] = item }
        let merged = Array(byId.values).sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        return merged
    }

    var body: some View {
        let palette = themeManager.currentPalette
        VStack(spacing: 0) {
            headerSection(palette: palette)
            if viewModel.isLoading && displayedItems.isEmpty {
                Spacer()
                ProgressView()
                    .tint(palette.brandTint)
                Text("Loading feed...")
                    .font(.themeCallout())
                    .foregroundStyle(palette.mutedText)
                    .padding(.top, Theme.spaceM)
                Spacer()
            } else if displayedItems.isEmpty {
                Spacer()
                feedEmptyState(message: viewModel.errorMessage, palette: palette)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: Theme.spaceL) {
                        ForEach(displayedItems) { item in
                            FeedCard(item: item, palette: palette, onVote: { voteType in
                                Task { await viewModel.voteOnContent(contentId: item.id, voteType: voteType) }
                            })
                            .onAppear {
                                Task { await viewModel.loadMoreIfNeeded(currentId: item.id) }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.top, Theme.spaceM)
                    .padding(.bottom, Theme.spaceXXL)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Reload from disk so after login we show the current user's saved posts
            MySubmittedContentStore.shared.reloadForCurrentUser()
        }
        .task { await viewModel.loadFeed() }
        .refreshable { await viewModel.loadFeed() }
    }

    private func headerSection(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Theme.spaceM) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                Text("Feeds")
                    .font(.themeTitle())
                    .foregroundStyle(.white)
                Spacer()
            }
            Text("What everyone is sharing")
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

    @ViewBuilder
    private func feedEmptyState(message: String?, palette: ThemePalette) -> some View {
        VStack(spacing: Theme.spaceM) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(palette.mutedText)
            Text("No posts yet")
                .font(.themeHeadline())
                .foregroundStyle(palette.text)
            if let msg = message, !msg.isEmpty {
                Text(msg)
                    .font(.themeCaption())
                    .foregroundStyle(palette.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spaceXL)
                Button("Try again") {
                    Task { await viewModel.loadFeed() }
                }
                .font(.themeHeadline())
                .foregroundStyle(palette.brandTint)
                .padding(.top, 4)
            }
            Text("Share something from Home to see it here. Pull down to refresh.")
                .font(.themeCaption())
                .foregroundStyle(palette.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spaceXL)
        }
    }
}

// MARK: - Feed card (Instagram/Facebook style: author, content, engagement)
private struct FeedCard: View {
    let item: ContentItem
    var palette: ThemePalette
    let onVote: (String) -> Void

    private var categoryColor: Color {
        (ContentCategory(rawValue: item.category) ?? .encouragement).color
    }

    private var categoryName: String {
        (ContentCategory(rawValue: item.category) ?? .encouragement).displayName
    }

    private var authorName: String {
        item.submitterUsername ?? item.author ?? "Anonymous"
    }

    private var authorInitial: String {
        String(authorName.prefix(1)).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM) {
            // Author row
            HStack(spacing: Theme.spaceM) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.25))
                        .frame(width: 44, height: 44)
                    Text(authorInitial)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(categoryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(authorName)
                        .font(.themeSubheadline())
                        .foregroundStyle(palette.text)
                    HStack(spacing: 6) {
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
                Spacer()
            }

            // Content body
            Text(item.displayText)
                .font(.themeBody())
                .foregroundStyle(palette.text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let answer = item.answer, !answer.isEmpty, item.contentType == "qa" {
                Text(answer)
                    .font(.themeCallout())
                    .foregroundStyle(palette.mutedText)
                    .italic()
            }

            // Engagement (like / dislike)
            HStack(spacing: Theme.spaceL) {
                Button {
                    onVote("up")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: (item.userVote == "up" ? "hand.thumbsup.fill" : "hand.thumbsup"))
                            .foregroundStyle(item.userVote == "up" ? categoryColor : palette.mutedText)
                        Text("\(item.upvotes)")
                            .font(.themeCaption())
                            .foregroundStyle(palette.mutedText)
                    }
                }
                .buttonStyle(.plain)
                Button {
                    onVote("down")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: (item.userVote == "down" ? "hand.thumbsdown.fill" : "hand.thumbsdown"))
                            .foregroundStyle(item.userVote == "down" ? Color.errorSoft : palette.mutedText)
                        Text("\(item.downvotes)")
                            .font(.themeCaption())
                            .foregroundStyle(palette.mutedText)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(Theme.spaceL)
        .background(palette.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
    }
}

#Preview {
    NavigationStack {
        FeedsView()
    }
}
