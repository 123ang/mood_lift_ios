import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    private let authService = AuthService.shared

    private let gridColumns = [
        GridItem(.flexible(), spacing: Theme.spaceM),
        GridItem(.flexible(), spacing: Theme.spaceM)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                VStack(alignment: .center, spacing: Theme.spaceXL) {
                    greetingBlock
                    checkinHeroCard
                    pointsPill
                    moodBoosterSectionHeader
                    categoryGrid
                    NavigationLink(destination: SubmitContentView()) {
                        MoodButton(title: "Submit your own content", icon: "plus.circle.fill", style: .primary, action: {})
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.bottom, Theme.spaceXXL)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.appBackground)
        .navigationBarHidden(true)
        .task { await viewModel.loadCheckinInfo() }
        .refreshable {
            await viewModel.loadCheckinInfo()
            await authService.refreshProfile()
        }
        .alert("You're in! \u{1F389}", isPresented: $viewModel.showCheckinSuccess) {
            Button("Yay!", role: .cancel) { }
        } message: {
            Text("You earned \(viewModel.pointsEarned) points. Keep the streak going!")
        }
        .onChange(of: viewModel.showCheckinSuccess) { _, new in
            if new { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        }
    }

    // MARK: - Header (soft gradient, centered, prominent title)
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: Theme.spaceM) {
                HStack(spacing: Theme.spaceS) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.98))
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    Text("MoodLift")
                        .font(.themeDisplayTitle())
                        .foregroundStyle(.white)
                        .tracking(0.8)
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.spaceXL)
                .padding(.bottom, Theme.spaceL)
            }
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            welcomePill
                .offset(y: 18)
                .zIndex(1)
        }
    }

    private var welcomePill: some View {
        Text(greetingText)
            .font(.themeSubheadline())
            .foregroundStyle(Color.darkText)
            .padding(.horizontal, Theme.spaceL)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            )
    }

    private var greetingText: String {
        let name = authService.currentUser?.username ?? "there"
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning, \(name) \u{1F44B}" }
        if hour < 17 { return "Good afternoon, \(name)" }
        return "Good evening, \(name) \u{1F31F}"
    }

    // MARK: - Greeting area (emotional message, centered)
    private var greetingBlock: some View {
        Text(emotionalMessage)
            .font(.themeCallout())
            .foregroundStyle(Color.lightText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, Theme.spaceXL)
            .padding(.top, Theme.spaceL)
    }

    private var emotionalMessage: String {
        if viewModel.checkinInfo?.canCheckin == true {
            return "A quick check-in can set the tone for your day."
        }
        if (viewModel.checkinInfo?.currentStreak ?? 0) > 0 {
            return "You're on a roll. Keep that good energy going!"
        }
        return "Take a moment for yourself."
    }

    // MARK: - Check-in hero card (centered content)
    private var checkinHeroCard: some View {
        SoftCard(
            backgroundColor: Color.primaryCardTint,
            cornerRadius: Theme.radiusXLarge,
            padding: Theme.spaceXL,
            useShadow: true,
            elevatedShadow: true,
            borderColor: Color.brandPrimary.opacity(0.2),
            contentAlignment: .center
        ) {
            VStack(alignment: .center, spacing: Theme.spaceL) {
                HStack(spacing: Theme.spaceS) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.brandPrimary)
                    Text("Daily check-in")
                        .font(.themeTitleSmall())
                        .foregroundStyle(Color.darkText)
                }

                if let streak = viewModel.checkinInfo?.currentStreak, streak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.reminderSoft)
                        Text("\(streak) day streak")
                            .font(.themeCaptionMedium())
                            .foregroundStyle(Color.darkText)
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.reminderSoftBg))
                }

                if viewModel.checkinInfo?.canCheckin == true {
                    Text("Tap below to check in and earn points")
                        .font(.themeCaption())
                        .foregroundStyle(Color.lightText)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await viewModel.performCheckin() }
                } label: {
                    Group {
                        if viewModel.isCheckingIn {
                            ProgressView()
                                .tint(viewModel.checkinInfo?.canCheckin == true ? Color.darkText : .white)
                        } else {
                            HStack(spacing: 6) {
                                if viewModel.checkinInfo?.canCheckin != true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                }
                                Text(checkinButtonText)
                                    .font(.themeHeadline())
                            }
                            .foregroundStyle(viewModel.checkinInfo?.canCheckin == true ? Color.darkText : .white)
                        }
                    }
                    .frame(minWidth: 140)
                    .padding(.horizontal, Theme.spaceL)
                    .padding(.vertical, Theme.spaceM)
                    .background(
                        Capsule()
                            .fill(viewModel.checkinInfo?.canCheckin == true ? Color.successSoft : Color.brandPrimary)
                    )
                }
                .disabled(viewModel.checkinInfo?.canCheckin != true || viewModel.isCheckingIn)
                .opacity(viewModel.isCheckingIn ? 0.7 : 1)

                if viewModel.checkinInfo?.canCheckin != true {
                    Text("Come back tomorrow for your next check-in")
                        .font(.themeCaption())
                        .foregroundStyle(Color.mutedText)
                        .multilineTextAlignment(.center)
                }

                NavigationLink(destination: DailyCheckinView()) {
                    HStack(spacing: 4) {
                        Text("View streak details")
                            .font(.themeCaptionMedium())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Theme.spaceM)
    }

    private var checkinButtonText: String {
        if let info = viewModel.checkinInfo, info.canCheckin {
            return "Check in (+\(info.nextPoints) pts)"
        }
        return "Checked in today \u{2713}"
    }

    // MARK: - Section header (centered)
    private var moodBoosterSectionHeader: some View {
        VStack(spacing: Theme.spaceXS) {
            HStack(spacing: Theme.spaceS) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.brandPrimary)
                Text("Choose your mood booster")
                    .font(.themeHeadline())
                    .foregroundStyle(Color.darkText)
            }
            Text("Pick the energy you need today")
                .font(.themeCaption())
                .foregroundStyle(Color.lightText)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.spaceXS)
    }

    // MARK: - Points (soft pill, centered)
    private var pointsPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.darkText)
            Text("\(authService.currentUser?.points ?? 0) points")
                .font(.themeCaptionMedium())
                .foregroundStyle(Color.darkText)
        }
        .padding(.horizontal, Theme.spaceM)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.accentWarm))
    }

    // MARK: - Category grid (soft cards, mood energy — no "free" badge)
    private var categoryGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: Theme.spaceM) {
            ForEach(ContentCategory.allCases, id: \.self) { category in
                NavigationLink(destination: ContentDetailView(category: category)) {
                    CategoryCard(category: category)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.spaceM)
    }
}

// MARK: - Category Card (soft, centered content)
private struct CategoryCard: View {
    let category: ContentCategory

    var body: some View {
        VStack(alignment: .center, spacing: Theme.spaceS) {
            Text(category.displayName)
                .font(.themeHeadline())
                .foregroundStyle(Color.darkText)
                .multilineTextAlignment(.center)
            Image(category.imageAssetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(category.color.opacity(0.9))
            Text(category.description)
                .font(.themeCaption())
                .foregroundStyle(Color.lightText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(Theme.spaceL)
        .frame(maxWidth: .infinity)
        .aspectRatio(0.88, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .fill(category.lightColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusLarge)
                        .strokeBorder(category.color.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Theme.elevatedCardShadow().color, radius: Theme.elevatedCardShadow().radius, x: 0, y: Theme.elevatedCardShadow().y)
        )
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
