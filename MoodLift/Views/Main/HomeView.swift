import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    private let authService = AuthService.shared

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - Pink Header
                pinkHeader

                // MARK: - Main Content
                VStack(spacing: 20) {
                    // Check-in Card
                    checkinCard
                        .padding(.top, 40)

                    // Section Title
                    Text("Choose your mood booster")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.darkText)

                    // Points Bar
                    pointsBar

                    // Category Grid
                    categoryGrid

                    // Submit Content Button
                    NavigationLink(destination: SubmitContentView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Submit Your Own Content")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.primaryGradientStart, .primaryGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .primaryGradientStart.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .task {
            await viewModel.loadCheckinInfo()
        }
        .refreshable {
            await viewModel.loadCheckinInfo()
            await authService.refreshProfile()
        }
        .alert("Check-in Successful! \u{1F389}", isPresented: $viewModel.showCheckinSuccess) {
            Button("Awesome!", role: .cancel) { }
        } message: {
            Text("You earned \(viewModel.pointsEarned) points!")
        }
    }

    // MARK: - Pink Header

    private var pinkHeader: some View {
        ZStack(alignment: .bottom) {
            // Pink background with title
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.encouragementPink)

                        Text("MOODLIFT")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.darkText)
                            .tracking(1)
                    }
                    .padding(.top, 32)
                }
                .padding(.bottom, 24)

                // Thick dark border divider
                Rectangle()
                    .fill(Color.borderColor)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .background(Color.encouragementPinkLight)

            // Floating Welcome Pill
            welcomePill
                .offset(y: 18)
                .zIndex(1)
        }
    }

    private var welcomePill: some View {
        Text("Welcome back, \(authService.currentUser?.username ?? "User") \u{1F44B}")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.darkText)
            .padding(.horizontal, 28)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.borderColor, lineWidth: 3)
                    )
                    .shadow(color: .borderColor.opacity(0.25), radius: 12, y: 6)
            )
    }

    // MARK: - Check-in Card

    private var checkinCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 28))
                    .foregroundStyle(.darkText)

                Text("Daily Check-in")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.darkText)
            }

            if viewModel.checkinInfo?.canCheckin == true {
                Text("Check in to keep your streak!")
                    .font(.system(size: 14))
                    .foregroundStyle(.darkText)
            }

            // Streak display
            if let streak = viewModel.checkinInfo?.currentStreak, streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.warningOrange)
                    Text("\(streak) day streak!")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.warningOrange)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.warningOrange.opacity(0.12))
                )
            }

            // Check-in Button
            Button {
                Task { await viewModel.performCheckin() }
            } label: {
                Group {
                    if viewModel.isCheckingIn {
                        ProgressView()
                            .tint(viewModel.checkinInfo?.canCheckin == true ? .darkText : .white)
                    } else {
                        HStack(spacing: 6) {
                            if viewModel.checkinInfo?.canCheckin != true {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                            }
                            Text(checkinButtonText)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                }
                .frame(minWidth: 120)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .foregroundStyle(viewModel.checkinInfo?.canCheckin == true ? .darkText : .white)
                .background(
                    Capsule()
                        .fill(viewModel.checkinInfo?.canCheckin == true ? Color.successGreen.opacity(0.2) : Color.borderColor)
                        .overlay(
                            Capsule()
                                .stroke(
                                    viewModel.checkinInfo?.canCheckin == true ? Color.successGreen : Color.borderColor,
                                    lineWidth: 2
                                )
                        )
                )
            }
            .disabled(viewModel.checkinInfo?.canCheckin != true || viewModel.isCheckingIn)
            .opacity(viewModel.isCheckingIn ? 0.6 : 1.0)

            if viewModel.checkinInfo?.canCheckin != true {
                Text("Come back tomorrow for your next check-in!")
                    .font(.system(size: 13))
                    .foregroundStyle(.lightText)
                    .multilineTextAlignment(.center)
            }

            // Link to full check-in view
            NavigationLink(destination: DailyCheckinView()) {
                HStack(spacing: 4) {
                    Text("View streak details")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.encouragementPink)
            }
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.encouragementPinkLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.borderColor, lineWidth: 4)
                )
                .shadow(color: .borderColor.opacity(0.12), radius: 12, y: 2)
        )
        .padding(.horizontal, 16)
    }

    private var checkinButtonText: String {
        if let info = viewModel.checkinInfo, info.canCheckin {
            return "Check in now! (+\(info.nextPoints) pts)"
        }
        return "Checked in today \u{2713}"
    }

    // MARK: - Points Bar

    private var pointsBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(.darkText)

            Text("\(authService.currentUser?.points ?? 0) Points")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.darkText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.accentYellow)
                .overlay(
                    Capsule()
                        .stroke(Color.borderColor, lineWidth: 3)
                )
                .shadow(color: .borderColor.opacity(0.08), radius: 4, y: 2)
        )
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(ContentCategory.allCases, id: \.self) { category in
                NavigationLink(destination: ContentDetailView(category: category)) {
                    CategoryCard(category: category)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Category Card

private struct CategoryCard: View {
    let category: ContentCategory

    var body: some View {
        VStack(spacing: 8) {
            Text(category.displayName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.darkText)

            Image(systemName: category.icon)
                .font(.system(size: 48))
                .foregroundStyle(.darkText.opacity(0.7))
                .frame(height: 64)

            Text(category.description)
                .font(.system(size: 12))
                .foregroundStyle(.darkText)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Spacer(minLength: 0)

            // Free badge
            Text("free")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.borderColor)
                )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .aspectRatio(0.85, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(category.lightColor)
                .shadow(color: .borderColor.opacity(0.12), radius: 12, y: 4)
        )
    }
}

// MARK: - Loading Skeleton

private struct HomeLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 120)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 40)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(0.85, contentMode: .fit)
                }
            }
        }
        .padding(16)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}