import SwiftUI

struct DailyCheckinView: View {
    @State private var viewModel = HomeViewModel()
    @State private var animateStreak = false
    @Environment(\.dismiss) private var dismiss
    private let authService = AuthService.shared

    // Days of the week labels
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Hero Section
                heroSection

                // MARK: - Streak Card
                streakCard

                // MARK: - Week Calendar
                weekCalendar

                // MARK: - Check-in Button
                checkinButton

                // MARK: - Rewards Info
                rewardsInfo

                // MARK: - Points Calculator
                pointsCalculator
            }
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#2ecc71"),
                    Color(hex: "#27ae60"),
                    Color(hex: "#1abc9c")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.loadCheckinInfo()
            withAnimation(.spring(response: 0.6).delay(0.3)) {
                animateStreak = true
            }
        }
        .alert("Check-in Successful! \u{1F389}", isPresented: $viewModel.showCheckinSuccess) {
            Button("Awesome!", role: .cancel) { }
        } message: {
            Text("You earned \(viewModel.pointsEarned) points! Keep it up!")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Top bar with back button
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
                }

                Spacer()

                // Points badge
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("\(authService.currentUser?.points ?? 0)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.darkText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.accentYellow)
                        .overlay(
                            Capsule()
                                .stroke(Color.borderColor, lineWidth: 2)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Large calendar icon
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .scaleEffect(animateStreak ? 1.0 : 0.7)
                .opacity(animateStreak ? 1.0 : 0)

            Text("Daily Check-in")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Build Your Streak!")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: 8) {
            // Flame icon
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.warningOrange)
                .shadow(color: .warningOrange.opacity(0.4), radius: 8, y: 2)

            // Large streak number
            Text("\(viewModel.checkinInfo?.currentStreak ?? 0)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Color.darkText)
                .scaleEffect(animateStreak ? 1.0 : 0.5)
                .opacity(animateStreak ? 1.0 : 0)

            Text("days")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color.lightText)

            // Total check-ins
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.successGreen)
                Text("\(viewModel.checkinInfo?.totalCheckins ?? 0) total check-ins")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.lightText)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.borderColor, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.1), radius: 16, y: 6)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Week Calendar

    private var weekCalendar: some View {
        VStack(spacing: 12) {
            Text("This Week")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    weekDayCircle(dayIndex: dayIndex)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func weekDayCircle(dayIndex: Int) -> some View {
        let isToday = dayIndex == currentDayOfWeekIndex
        let isChecked = isDayChecked(dayIndex: dayIndex)

        VStack(spacing: 6) {
            Text(weekDays[dayIndex])
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            ZStack {
                Circle()
                    .fill(isChecked ? .white : .white.opacity(0.15))
                    .frame(width: 42, height: 42)

                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.successGreen)
                } else if isToday {
                    Circle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .overlay(
                Circle()
                    .stroke(isToday ? .white : .clear, lineWidth: 3)
                    .frame(width: 42, height: 42)
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Check-in Button

    private var checkinButton: some View {
        Button {
            Task { await viewModel.performCheckin() }
        } label: {
            Group {
                if viewModel.isCheckingIn {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.checkinInfo?.canCheckin == true ? "hand.tap.fill" : "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text(checkinButtonLabel)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        viewModel.checkinInfo?.canCheckin == true
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#f39c12"), Color(hex: "#e67e22")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                              )
                            : AnyShapeStyle(Color.white.opacity(0.25))
                    )
                    .shadow(
                        color: viewModel.checkinInfo?.canCheckin == true ? Color(hex: "#f39c12").opacity(0.4) : .clear,
                        radius: 12,
                        y: 4
                    )
            )
        }
        .disabled(viewModel.checkinInfo?.canCheckin != true || viewModel.isCheckingIn)
        .padding(.horizontal, 20)
    }

    private var checkinButtonLabel: String {
        if viewModel.checkinInfo?.canCheckin == true {
            return "Check in now! (+\(viewModel.checkinInfo?.nextPoints ?? 0) points)"
        }
        return "Already checked in today"
    }

    // MARK: - Rewards Info

    private var rewardsInfo: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.warningOrange)
                Text("Streak Rewards")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.darkText)
            }

            VStack(spacing: 12) {
                rewardRow(icon: "1.circle.fill", period: "Week 1", points: "~7 points", color: .factsGreen)
                rewardRow(icon: "2.circle.fill", period: "Week 2", points: "~14 points", color: .jokesBlue)
                rewardRow(icon: "calendar", period: "Month 1", points: "~65 points", color: .encouragementPink)
            }

            Text("Points increase as your streak grows!")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.lightText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.borderColor, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func rewardRow(icon: String, period: String, points: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 36)

            Text(period)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.darkText)

            Spacer()

            Text(points)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(color.opacity(0.12))
                )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Points Calculator

    private var pointsCalculator: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.inspirationYellow)
                Text("Points Projection")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.darkText)
            }

            let nextPoints = viewModel.checkinInfo?.nextPoints ?? 1

            VStack(spacing: 12) {
                projectionRow(label: "Next check-in", value: "+\(nextPoints) pts")
                projectionRow(label: "7-day projection", value: "~\(nextPoints * 7) pts")
                projectionRow(label: "30-day projection", value: "~\(nextPoints * 30) pts")

                Divider()

                HStack {
                    Text("Current balance")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.darkText)
                    Spacer()
                    Text("\(authService.currentUser?.points ?? 0) pts")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inspirationYellow)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.borderColor, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func projectionRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.lightText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.darkText)
        }
    }

    // MARK: - Helpers

    private var currentDayOfWeekIndex: Int {
        // Monday = 0, Sunday = 6
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        return weekday == 1 ? 6 : weekday - 2
    }

    private func isDayChecked(dayIndex: Int) -> Bool {
        guard let streak = viewModel.checkinInfo?.currentStreak, streak > 0 else { return false }
        let todayIndex = currentDayOfWeekIndex
        let checkedInToday = viewModel.checkinInfo?.canCheckin == false

        // Show checked days based on streak (going backwards from today)
        if checkedInToday {
            let daysBack = todayIndex - dayIndex
            if daysBack >= 0 && daysBack < streak {
                return true
            }
        } else {
            // Haven't checked in today, so streak was from yesterday backwards
            let daysBack = (todayIndex - 1) - dayIndex
            if daysBack >= 0 && daysBack < streak {
                return true
            }
        }
        return false
    }
}

#Preview {
    DailyCheckinView()
}
