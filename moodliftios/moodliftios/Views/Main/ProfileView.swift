import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    private var user: User? { AuthService.shared.currentUser }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                VStack(spacing: 24) {
                    statsGrid
                    recentActivitySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
        .refreshable {
            await viewModel.loadProfile()
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

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 100, height: 100)

                    Text(userInitial)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                VStack(spacing: 6) {
                    Text(user?.username ?? "User")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(user?.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))

                    if let memberSince = viewModel.stats?.memberSince ?? user?.createdAt {
                        Text("Member since \(memberSince.formatted(.dateTime.year()))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                }
            }
            .padding(.vertical, 40)
            .padding(.top, 10)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(viewModel.stats?.currentStreak ?? user?.currentStreak ?? 0)",
                    label: "Current Streak",
                    gradientColors: [Color(hex: "#ff6b6b"), Color(hex: "#ee5a24")]
                )
                StatCard(
                    icon: "calendar.badge.checkmark",
                    value: "\(viewModel.stats?.totalCheckins ?? user?.totalCheckins ?? 0)",
                    label: "Total Check-ins",
                    gradientColors: [Color(hex: "#4ecdc4"), Color(hex: "#2ecc71")]
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    icon: "star.fill",
                    value: "\(viewModel.stats?.pointsBalance ?? user?.pointsBalance ?? 0)",
                    label: "Points Balance",
                    gradientColors: [Color(hex: "#ffd93d"), Color(hex: "#f39c12")]
                )
                StatCard(
                    icon: "trophy.fill",
                    value: "\(viewModel.stats?.totalPointsEarned ?? user?.totalPointsEarned ?? 0)",
                    label: "Total Earned",
                    gradientColors: [Color(hex: "#45b7d1"), Color(hex: "#3498db")]
                )
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.encouragementPink)

                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.darkText)

                Spacer()

                if !viewModel.recentTransactions.isEmpty {
                    NavigationLink(destination: RecentActivityView()) {
                        Text("View All")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encouragementPink)
                    }
                }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 30)
                    Spacer()
                }
            } else if viewModel.recentTransactions.isEmpty {
                emptyActivityState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                        TransactionRow(transaction: transaction)

                        if index < min(viewModel.recentTransactions.count, 5) - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderColor.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            }
        }
    }

    // MARK: - Empty Activity State

    private var emptyActivityState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(Color.lightText.opacity(0.5))

            Text("No recent activity")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.lightText)

            Text("Check in daily to start earning points!")
                .font(.caption)
                .foregroundStyle(Color.lightText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderColor.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var userInitial: String {
        let name = user?.username ?? "U"
        return String(name.prefix(1)).uppercased()
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradientColors: [Color]

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.white)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: gradientColors[0].opacity(0.3), radius: 6, y: 3)
    }
}

// MARK: - Transaction Row

private struct TransactionRow: View {
    let transaction: PointsTransaction

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(transaction.isEarned ? Color.successGreen.opacity(0.15) : Color.warningOrange.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.isEarned ? "plus.circle.fill" : "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(transaction.isEarned ? Color.successGreen : Color.warningOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description ?? "Transaction")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.darkText)
                    .lineLimit(2)

                if let date = transaction.createdAt {
                    Text(date.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(Color.lightText)
                }
            }

            Spacer()

            Text(transaction.isEarned ? "+\(transaction.pointsAmount)" : "-\(transaction.pointsAmount)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(transaction.isEarned ? Color.successGreen : Color.warningOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
