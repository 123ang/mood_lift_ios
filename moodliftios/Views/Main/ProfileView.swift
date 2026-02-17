import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    private var user: User? { AuthService.shared.currentUser }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                VStack(spacing: Theme.spaceL) {
                    achievementsCard
                    myContentSection
                    savedItemsSection
                    recentActivitySection
                }
                .padding(.horizontal, Theme.spaceM)
                .padding(.top, Theme.spaceL)
                .padding(.bottom, Theme.spaceXXL)
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            MySubmittedContentStore.shared.reloadForCurrentUser()
        }
        .task {
            await viewModel.loadProfile()
            await viewModel.loadMyContent()
            AuthService.shared.setLastKnownStatsBalance(viewModel.stats?.pointsBalance)
        }
        .refreshable {
            await viewModel.loadProfile()
            await viewModel.loadMyContent()
            AuthService.shared.setLastKnownStatsBalance(viewModel.stats?.pointsBalance)
        }
    }

    // MARK: - Header (personal space feel)
    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: Theme.spaceL) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 88, height: 88)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 88, height: 88)
                    Text(userInitial)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(spacing: 6) {
                    Text(user?.username ?? "User")
                        .font(.themeTitle())
                        .foregroundStyle(.white)
                    Text(user?.email ?? "")
                        .font(.themeCaption())
                        .foregroundStyle(.white.opacity(0.9))
                    if let memberSince = viewModel.stats?.memberSince ?? user?.createdAt {
                        Text("With you since \(memberSince.formatted(.dateTime.year()))")
                            .font(.themeCaption())
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(.vertical, Theme.spaceXL)
            .padding(.top, Theme.spaceS)
        }
    }

    // MARK: - Achievements (gentle, reflective — not analytics)
    private var achievementsCard: some View {
        SoftCard(
            backgroundColor: Color.cardBackground,
            cornerRadius: Theme.radiusLarge,
            padding: Theme.spaceL,
            useShadow: true
        ) {
            VStack(alignment: .leading, spacing: Theme.spaceM) {
                SectionHeader(icon: "sparkles", title: "Your journey", subtitle: "Little wins add up")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spaceM) {
                    AchievementPill(
                        icon: "flame.fill",
                        value: "\(viewModel.stats?.currentStreak ?? user?.currentStreak ?? 0)",
                        label: "Day streak",
                        tint: .encouragementPink
                    )
                    AchievementPill(
                        icon: "calendar.badge.checkmark",
                        value: "\(viewModel.stats?.totalCheckins ?? user?.totalCheckins ?? 0)",
                        label: "Check-ins",
                        tint: .factsGreen
                    )
                    AchievementPill(
                        icon: "star.fill",
                        value: "\(AuthService.shared.displayPoints)",
                        label: "Points",
                        tint: .inspirationYellow
                    )
                    AchievementPill(
                        icon: "heart.fill",
                        value: "\(viewModel.stats?.totalPointsEarned ?? user?.totalPointsEarned ?? 0)",
                        label: "Total earned",
                        tint: .jokesBlue
                    )
                }
                if showWelcomeBonusHint {
                    Text("Your points are from your welcome bonus for joining. Check in daily to earn more.")
                        .font(.themeCaption())
                        .foregroundStyle(Color.lightText)
                        .multilineTextAlignment(.center)
                        .padding(.top, Theme.spaceS)
                }
            }
        }
    }

    // MARK: - My Content (posts you shared + total likes)
    private var myContentSection: some View {
        NavigationLink(destination: MyContentView()) {
            HStack(spacing: Theme.spaceM) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                        .fill(Color.jokesBlueLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.jokesBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Content")
                        .font(.themeHeadline())
                        .foregroundStyle(Color.darkText)
                    Text(myContentSubtitle)
                        .font(.themeCaption())
                        .foregroundStyle(Color.lightText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.lightText)
            }
            .padding(Theme.spaceM)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
        .buttonStyle(.plain)
    }

    private var myContentSubtitle: String {
        let count = viewModel.myContent.count
        let likes = viewModel.totalLikesReceived
        if count == 0 { return "Your posts and likes" }
        if count == 1 {
            return likes == 1 ? "1 post · 1 like" : "1 post · \(likes) likes"
        }
        return "\(count) posts · \(likes) likes"
    }

    /// Points to show on Profile: use the higher of auth balance or stats balance so check-in rewards show when stats is updated but auth profile isn’t yet.
    private var showWelcomeBonusHint: Bool {
        let checkins = viewModel.stats?.totalCheckins ?? user?.totalCheckins ?? 0
        return checkins == 0 && AuthService.shared.displayPoints > 0
    }

    // MARK: - Saved items (moved from tab bar; access from Profile)
    private var savedItemsSection: some View {
        NavigationLink(destination: SavedItemsView()) {
            HStack(spacing: Theme.spaceM) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                        .fill(Color.primarySoftLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.brandPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved Items")
                        .font(.themeHeadline())
                        .foregroundStyle(Color.darkText)
                    Text("Your bookmarked content")
                        .font(.themeCaption())
                        .foregroundStyle(Color.lightText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.lightText)
            }
            .padding(Theme.spaceM)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent activity (softer framing)
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM) {
            HStack {
                SectionHeader(icon: "clock.arrow.circlepath", title: "Recent activity")
                Spacer()
                if !viewModel.recentTransactions.isEmpty {
                    NavigationLink(destination: RecentActivityView()) {
                        Text("View all")
                            .font(.themeCaptionMedium())
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.brandPrimary)
                        .padding(.vertical, Theme.spaceXL)
                    Spacer()
                }
            } else if viewModel.recentTransactions.isEmpty {
                emptyActivityState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                        TransactionRow(transaction: transaction)
                        if index < min(viewModel.recentTransactions.count, 5) - 1 {
                            Rectangle()
                                .fill(Color.borderColor.opacity(0.15))
                                .frame(height: 1)
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.vertical, Theme.spaceS)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
            }
        }
    }

    private var emptyActivityState: some View {
        VStack(spacing: Theme.spaceS) {
            Image(systemName: "leaf")
                .font(.system(size: 36))
                .foregroundStyle(Color.supportMint.opacity(0.7))
            Text("No recent activity")
                .font(.themeCallout())
                .foregroundStyle(Color.lightText)
            Text("Check in daily to start your journey")
                .font(.themeCaption())
                .foregroundStyle(Color.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spaceXL)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
    }

    private var userInitial: String {
        let name = user?.username ?? "U"
        return String(name.prefix(1)).uppercased()
    }
}

// MARK: - Achievement pill (soft, not stat box)
private struct AchievementPill: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: Theme.spaceS) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(tint)
            Text(value)
                .font(.themeTitleSmall())
                .foregroundStyle(Color.darkText)
            Text(label)
                .font(.themeCaption())
                .foregroundStyle(Color.lightText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spaceM)
        .padding(.horizontal, Theme.spaceS)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
    }
}

// MARK: - Transaction row (warm glow for earned, gentle for spent)
private struct TransactionRow: View {
    let transaction: PointsTransaction

    var body: some View {
        HStack(spacing: Theme.spaceM) {
            ZStack {
                Circle()
                    .fill(transaction.isEarned ? Color.successSoftBg : Color.reminderSoftBg)
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.isEarned ? "plus.circle.fill" : "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(transaction.isEarned ? Color.successSoft : Color.reminderSoft)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description ?? "Transaction")
                    .font(.themeCallout())
                    .foregroundStyle(Color.darkText)
                    .lineLimit(2)
                if let date = transaction.createdAt {
                    Text(date.formatted(.relative(presentation: .named)))
                        .font(.themeCaption())
                        .foregroundStyle(Color.lightText)
                }
            }
            Spacer()
            Text(transaction.isEarned ? "+\(transaction.pointsAmount)" : "-\(transaction.pointsAmount)")
                .font(.themeHeadline())
                .foregroundStyle(transaction.isEarned ? Color.successSoft : Color.reminderSoft)
        }
        .padding(.horizontal, Theme.spaceM)
        .padding(.vertical, Theme.spaceS + 2)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
