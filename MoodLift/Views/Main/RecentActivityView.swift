import SwiftUI

struct RecentActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var transactions: [PointsTransaction] = []
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var isLoadingMore = false

    private let purpleGradient = LinearGradient(
        colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            purpleGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                if isLoading && transactions.isEmpty {
                    loadingState
                } else if transactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadInitial()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Text("Recent Activity")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(transactions) { transaction in
                    ActivityTransactionCard(transaction: transaction)
                }

                if currentPage < totalPages {
                    Button {
                        Task { await loadMore() }
                    } label: {
                        if isLoadingMore {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 16)
                        } else {
                            Text("Load More")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 32)
                                .background(.white.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .refreshable {
            await loadInitial()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            Text("Loading activity...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 12)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.5))

            Text("No activity yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("Your points transactions will appear here")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Data Loading

    private func loadInitial() async {
        isLoading = true
        defer { isLoading = false }
        currentPage = 1

        do {
            let response = try await PointsService.shared.getPointsHistory(page: 1, limit: 20)
            transactions = response.data
            totalPages = response.totalPages
        } catch {
            // Handle error silently
        }
    }

    private func loadMore() async {
        guard !isLoadingMore, currentPage < totalPages else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await PointsService.shared.getPointsHistory(page: nextPage, limit: 20)
            transactions.append(contentsOf: response.data)
            currentPage = nextPage
            totalPages = response.totalPages
        } catch {
            // Handle error silently
        }
    }
}

// MARK: - Activity Transaction Card

private struct ActivityTransactionCard: View {
    let transaction: PointsTransaction

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(transaction.isEarned ? Color.successGreen : Color.warningOrange)
                    .frame(width: 44, height: 44)

                Image(systemName: transaction.isEarned ? "plus" : "minus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description ?? "Transaction")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.darkText)
                    .lineLimit(2)

                if let date = transaction.createdAt {
                    Text(formattedDate(date))
                        .font(.caption)
                        .foregroundStyle(Color.lightText)
                }
            }

            Spacer()

            Text(transaction.isEarned ? "+\(transaction.pointsAmount)" : "-\(transaction.pointsAmount)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(transaction.isEarned ? Color.successGreen : Color.warningOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    (transaction.isEarned ? Color.successGreen : Color.warningOrange).opacity(0.12)
                )
                .clipShape(Capsule())
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, " + date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, " + date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

#Preview {
    NavigationStack {
        RecentActivityView()
    }
}
