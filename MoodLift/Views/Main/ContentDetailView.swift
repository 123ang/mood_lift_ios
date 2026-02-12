import SwiftUI

struct ContentDetailView: View {
    let category: ContentCategory
    @State private var viewModel: ContentViewModel
    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var showAnswerForId: Set<String> = []
    @State private var selectedQuizAnswer: [String: String] = [:]
    @State private var showSaveSuccess = false
    @Environment(\.dismiss) private var dismiss
    private let authService = AuthService.shared

    init(category: ContentCategory) {
        self.category = category
        self._viewModel = State(initialValue: ContentViewModel(category: category))
    }

    var body: some View {
        ZStack {
            // Category-colored background
            category.gradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // MARK: - Category Title & Counter
                VStack(spacing: 6) {
                    Text(category.displayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if !viewModel.dailyContent.isEmpty {
                        Text("\(viewModel.currentIndex + 1)/\(viewModel.dailyContent.count)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)

                // MARK: - Content Cards
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                    Text("Loading content...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 12)
                    Spacer()
                } else if viewModel.dailyContent.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    // Swipeable card area
                    TabView(selection: $viewModel.currentIndex) {
                        ForEach(Array(viewModel.dailyContent.enumerated()), id: \.element.id) { index, item in
                            contentCard(for: item)
                                .tag(index)
                                .padding(.horizontal, 20)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.loadDailyContent()
        }
        .alert("Content Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This content has been added to your saved items.")
        }
        .sheet(isPresented: $showReportSheet) {
            reportSheet
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Back button
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

            // Points pill
            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("\(authService.currentUser?.points ?? 0)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.darkText)
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
    }

    // MARK: - Content Card

    @ViewBuilder
    private func contentCard(for item: DailyContentItem) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if item.isUnlocked, let content = item.content {
                    // Unlocked content
                    unlockedContent(content: content, item: item)
                } else {
                    // Locked content
                    lockedContent(item: item)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        )
        .padding(.bottom, 20)
    }

    // MARK: - Unlocked Content

    @ViewBuilder
    private func unlockedContent(content: ContentItem, item: DailyContentItem) -> some View {
        // Content type badge
        HStack {
            contentTypeBadge(type: content.contentType)
            Spacer()

            // Report button
            Button {
                showReportSheet = true
            } label: {
                Image(systemName: "flag")
                    .font(.system(size: 14))
                    .foregroundStyle(.lightText)
                    .padding(8)
                    .background(Circle().fill(Color.gray.opacity(0.1)))
            }
        }

        // Main content based on type
        switch content.contentType {
        case "quiz":
            quizContent(content: content)
        case "qa":
            qaContent(content: content)
        default:
            textContent(content: content)
        }

        // Author attribution
        if let author = content.author, !author.isEmpty {
            HStack(spacing: 4) {
                Text("\u{2014}")
                Text(author)
                    .italic()
            }
            .font(.system(size: 13))
            .foregroundStyle(.lightText)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }

        Divider()
            .padding(.vertical, 4)

        // Action buttons row
        actionButtons(content: content)
    }

    // MARK: - Text Content

    @ViewBuilder
    private func textContent(content: ContentItem) -> some View {
        Text(content.displayText)
            .font(.system(size: 20, weight: .medium, design: .serif))
            .foregroundStyle(.darkText)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }

    // MARK: - Quiz Content

    @ViewBuilder
    private func quizContent(content: ContentItem) -> some View {
        VStack(spacing: 16) {
            // Question
            Text(content.question ?? content.displayText)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.darkText)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)

            // Options
            let options: [(String, String?)] = [
                ("A", content.optionA),
                ("B", content.optionB),
                ("C", content.optionC),
                ("D", content.optionD)
            ]

            ForEach(options.compactMap { label, value in
                value.map { (label, $0) }
            }, id: \.0) { label, value in
                quizOptionButton(
                    label: label,
                    value: value,
                    contentId: content.id,
                    correctOption: content.correctOption
                )
            }
        }
    }

    @ViewBuilder
    private func quizOptionButton(label: String, value: String, contentId: String, correctOption: String?) -> some View {
        let selected = selectedQuizAnswer[contentId]
        let isSelected = selected == label
        let isCorrect = label == correctOption
        let hasAnswered = selected != nil

        Button {
            if !hasAnswered {
                withAnimation(.spring(response: 0.3)) {
                    selectedQuizAnswer[contentId] = label
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Label circle
                ZStack {
                    Circle()
                        .fill(optionCircleColor(isSelected: isSelected, isCorrect: isCorrect, hasAnswered: hasAnswered))
                        .frame(width: 32, height: 32)
                    Text(label)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected || (hasAnswered && isCorrect) ? .white : .darkText)
                }

                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.darkText)
                    .multilineTextAlignment(.leading)

                Spacer()

                if hasAnswered && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.successGreen)
                }
                if hasAnswered && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.errorRed)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(optionBgColor(isSelected: isSelected, isCorrect: isCorrect, hasAnswered: hasAnswered))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(optionBorderColor(isSelected: isSelected, isCorrect: isCorrect, hasAnswered: hasAnswered), lineWidth: 2)
                    )
            )
        }
        .disabled(hasAnswered)
    }

    private func optionCircleColor(isSelected: Bool, isCorrect: Bool, hasAnswered: Bool) -> Color {
        if hasAnswered && isCorrect { return .successGreen }
        if isSelected && !isCorrect { return .errorRed }
        if isSelected { return .encouragementPink }
        return Color.gray.opacity(0.15)
    }

    private func optionBgColor(isSelected: Bool, isCorrect: Bool, hasAnswered: Bool) -> Color {
        if hasAnswered && isCorrect { return Color.successGreen.opacity(0.08) }
        if hasAnswered && isSelected && !isCorrect { return Color.errorRed.opacity(0.08) }
        return Color.gray.opacity(0.04)
    }

    private func optionBorderColor(isSelected: Bool, isCorrect: Bool, hasAnswered: Bool) -> Color {
        if hasAnswered && isCorrect { return .successGreen.opacity(0.3) }
        if hasAnswered && isSelected && !isCorrect { return .errorRed.opacity(0.3) }
        if isSelected { return .encouragementPink.opacity(0.3) }
        return Color.gray.opacity(0.15)
    }

    // MARK: - Q&A Content

    @ViewBuilder
    private func qaContent(content: ContentItem) -> some View {
        VStack(spacing: 16) {
            // Question
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(category.color)

                Text(content.question ?? content.displayText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.darkText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)

            // Reveal / Answer
            if showAnswerForId.contains(content.id) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.inspirationYellow)
                        Text("Answer")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.darkText)
                    }

                    Text(content.answer ?? "")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.darkText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.successGreen.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.successGreen.opacity(0.2), lineWidth: 1)
                        )
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))
            } else {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        showAnswerForId.insert(content.id)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 14))
                        Text("Tap to reveal answer")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(category.color)
                    )
                }
            }
        }
    }

    // MARK: - Locked Content

    @ViewBuilder
    private func lockedContent(item: DailyContentItem) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(category.color.opacity(0.6))

            Text("Content Locked")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.darkText)

            Text("Use your points to unlock this content")
                .font(.system(size: 14))
                .foregroundStyle(.lightText)
                .multilineTextAlignment(.center)

            // Unlock button
            Button {
                Task {
                    await viewModel.unlockContent(contentId: item.contentId)
                }
            } label: {
                Group {
                    if viewModel.isUnlocking {
                        ProgressView()
                            .tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 15))
                            Text("Unlock for 5 points")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: category.color.opacity(0.3), radius: 8, y: 4)
                )
            }
            .disabled(viewModel.isUnlocking)
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(minHeight: 300)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(content: ContentItem) -> some View {
        HStack(spacing: 0) {
            // Upvote
            Button {
                Task { await viewModel.voteOnContent(contentId: content.id, voteType: "up") }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: content.userVote == "up" ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 20))
                    Text("\(content.upvotes)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(content.userVote == "up" ? .successGreen : .lightText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 36)

            // Downvote
            Button {
                Task { await viewModel.voteOnContent(contentId: content.id, voteType: "down") }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: content.userVote == "down" ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 20))
                    Text("\(content.downvotes)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(content.userVote == "down" ? .errorRed : .lightText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 36)

            // Save button
            Button {
                Task {
                    await viewModel.saveContent(contentId: content.id)
                    showSaveSuccess = true
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 20))
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.lightText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.05))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))

            Text("No content available")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Check back later for fresh \(category.displayName.lowercased()) content!")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Report Sheet

    private var reportSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Report Content")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.darkText)

                Text("Help us keep MoodLift positive by reporting inappropriate content.")
                    .font(.subheadline)
                    .foregroundStyle(.lightText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.darkText)

                    TextField("Describe the issue...", text: $reportReason, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 20)

                Button {
                    if let contentId = viewModel.currentItem?.contentId {
                        Task {
                            await viewModel.reportContent(contentId: contentId, reason: reportReason)
                            showReportSheet = false
                            reportReason = ""
                        }
                    }
                } label: {
                    Text("Submit Report")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(reportReason.isEmpty ? Color.gray : Color.errorRed)
                        )
                }
                .disabled(reportReason.isEmpty)
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showReportSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Content Type Badge

    @ViewBuilder
    private func contentTypeBadge(type: String) -> some View {
        let (icon, label): (String, String) = {
            switch type {
            case "quiz": return ("brain.head.profile", "Quiz")
            case "qa": return ("questionmark.bubble.fill", "Q&A")
            default: return ("text.quote", "Text")
            }
        }()

        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(category.lightColor)
        )
    }
}

#Preview {
    NavigationStack {
        ContentDetailView(category: .encouragement)
    }
}
