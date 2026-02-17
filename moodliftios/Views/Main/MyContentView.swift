import SwiftUI

struct MyContentView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var selectedItem: ContentItem?

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            if viewModel.isLoadingMyContent && viewModel.myContent.isEmpty {
                Spacer()
                ProgressView()
                    .tint(.brandPrimary)
                Text("Loading your content...")
                    .font(.themeCallout())
                    .foregroundStyle(Color.lightText)
                    .padding(.top, Theme.spaceM)
                Spacer()
            } else if viewModel.myContent.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: Theme.spaceM) {
                        ForEach(viewModel.myContent) { item in
                            MyContentRow(item: item) {
                                selectedItem = item
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.top, Theme.spaceM)
                    .padding(.bottom, Theme.spaceXXL)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadMyContent() }
        .refreshable { await viewModel.loadMyContent() }
        .sheet(item: $selectedItem) { item in
            MyContentDetailSheet(item: item)
        }
    }

    private var headerSection: some View {
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
        .background(headerGradient)
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

    private var emptyState: some View {
        VStack(spacing: Theme.spaceM) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(Color.mutedText)
            Text("No posts yet")
                .font(.themeHeadline())
                .foregroundStyle(Color.darkText)
            Text("Share encouragement, jokes, or fun facts from the Feeds tab and they'll show here with your like count.")
                .font(.themeCaption())
                .foregroundStyle(Color.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spaceXL)
        }
    }
}

// MARK: - Row: preview + likes, tappable
private struct MyContentRow: View {
    let item: ContentItem
    let onTap: () -> Void

    private var categoryColor: Color {
        (ContentCategory(rawValue: item.category) ?? .encouragement).color
    }

    private var categoryName: String {
        (ContentCategory(rawValue: item.category) ?? .encouragement).displayName
    }

    var body: some View {
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
                        .foregroundStyle(Color.darkText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: Theme.spaceS) {
                        Text(categoryName)
                            .font(.themeCaptionMedium())
                            .foregroundStyle(categoryColor)
                        if let date = item.createdAt {
                            Text("·")
                                .foregroundStyle(Color.mutedText)
                            Text(date.formatted(.relative(presentation: .named)))
                                .font(.themeCaption())
                                .foregroundStyle(Color.lightText)
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
                            .foregroundStyle(Color.darkText)
                    }
                    Text("likes")
                        .font(.themeCaption())
                        .foregroundStyle(Color.lightText)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.lightText)
            }
            .padding(Theme.spaceM)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sheet: full content read-only (same shape as feed card)
private struct MyContentDetailSheet: View {
    let item: ContentItem
    @Environment(\.dismiss) private var dismiss

    private var categoryColor: Color {
        (ContentCategory(rawValue: item.category) ?? .encouragement).color
    }

    private var categoryName: String {
        (ContentCategory(rawValue: item.category) ?? .encouragement).displayName
    }

    var body: some View {
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
                                .foregroundStyle(Color.darkText)
                            if let date = item.createdAt {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.themeCaption())
                                    .foregroundStyle(Color.lightText)
                            }
                        }
                        Spacer()
                    }

                    Text(item.displayText)
                        .font(.themeBody())
                        .foregroundStyle(Color.darkText)
                        .multilineTextAlignment(.leading)
                    if let answer = item.answer, !answer.isEmpty, item.contentType == "qa" {
                        Text(answer)
                            .font(.themeCallout())
                            .foregroundStyle(Color.lightText)
                            .italic()
                    }

                    HStack(spacing: Theme.spaceL) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundStyle(categoryColor)
                            Text("\(item.upvotes) upvotes")
                                .font(.themeCaption())
                                .foregroundStyle(Color.lightText)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .foregroundStyle(Color.lightText)
                            Text("\(item.downvotes) downvotes")
                                .font(.themeCaption())
                                .foregroundStyle(Color.lightText)
                        }
                        Spacer()
                        Text("Net: \(item.score) likes")
                            .font(.themeCaptionMedium())
                            .foregroundStyle(categoryColor)
                    }
                    .padding(.top, Theme.spaceS)
                }
                .padding(Theme.spaceL)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
                .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
                .padding(.horizontal, Theme.spaceM)
            }
            .background(Color.appBackground)
            .navigationTitle("Your post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.themeHeadline())
                        .foregroundStyle(Color.brandPrimary)
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
