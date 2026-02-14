import SwiftUI

struct SubmitContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SubmitContentViewModel()

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    contentTypePicker
                    categoryPicker
                    formFields
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Content Submitted!", isPresented: $viewModel.showSuccess) {
            Button("Awesome!") {
                dismiss()
            }
        } message: {
            Text("Thank you for sharing! Your content will be reviewed and published soon.")
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.primaryGradientStart, .primaryGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .encouragementPink.opacity(0.3), radius: 8, y: 4)

                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }

            Text("Share Content")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.darkText)

            Text("Help others by submitting uplifting content")
                .font(.subheadline)
                .foregroundStyle(Color.lightText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Content Type Picker

    private var contentTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONTENT TYPE")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.lightText)
                .tracking(0.5)

            HStack(spacing: 0) {
                ForEach(["text", "quiz", "qa"], id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.contentType = type
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: typeIcon(for: type))
                                .font(.system(size: 16))
                            Text(typeLabel(for: type))
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(viewModel.contentType == type ? Color.white : Color.darkText)
                        .background(
                            viewModel.contentType == type
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [.primaryGradientStart, .primaryGradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                : AnyShapeStyle(Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CATEGORY")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.lightText)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ContentCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedCategory = category
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(category.imageAssetName)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                Text(category.displayName)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .foregroundStyle(viewModel.selectedCategory == category ? .white : category.color)
                            .background(
                                viewModel.selectedCategory == category
                                    ? AnyShapeStyle(category.color)
                                    : AnyShapeStyle(category.color.opacity(0.1))
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        viewModel.selectedCategory == category ? Color.clear : category.color.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Form Fields

    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: 16) {
            switch viewModel.contentType {
            case "text":
                textFormFields
            case "quiz":
                quizFormFields
            case "qa":
                qaFormFields
            default:
                textFormFields
            }
        }
    }

    // MARK: - Text Form

    private var textFormFields: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CONTENT *")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.lightText)
                    .tracking(0.5)

                TextEditor(text: $viewModel.contentText)
                    .frame(minHeight: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
            }

            authorField
        }
    }

    // MARK: - Quiz Form

    private var quizFormFields: some View {
        VStack(spacing: 16) {
            formTextField(
                label: "QUESTION *",
                placeholder: "Enter your quiz question",
                text: $viewModel.question
            )

            formTextField(
                label: "OPTION A *",
                placeholder: "First option",
                text: $viewModel.optionA
            )

            formTextField(
                label: "OPTION B *",
                placeholder: "Second option",
                text: $viewModel.optionB
            )

            formTextField(
                label: "OPTION C",
                placeholder: "Third option (optional)",
                text: $viewModel.optionC
            )

            formTextField(
                label: "OPTION D",
                placeholder: "Fourth option (optional)",
                text: $viewModel.optionD
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("CORRECT ANSWER *")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.lightText)
                    .tracking(0.5)

                HStack(spacing: 0) {
                    ForEach(["A", "B", "C", "D"], id: \.self) { option in
                        Button {
                            viewModel.correctOption = option
                        } label: {
                            Text(option)
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(viewModel.correctOption == option ? Color.white : Color.darkText)
                                .background(
                                    viewModel.correctOption == option
                                        ? Color.successGreen
                                        : Color.white
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
            }
        }
    }

    // MARK: - Q&A Form

    private var qaFormFields: some View {
        VStack(spacing: 16) {
            formTextField(
                label: "QUESTION *",
                placeholder: "Enter your question",
                text: $viewModel.question
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("ANSWER *")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.lightText)
                    .tracking(0.5)

                TextEditor(text: $viewModel.answer)
                    .frame(minHeight: 100)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
            }
        }
    }

    // MARK: - Reusable Components

    private var authorField: some View {
        formTextField(
            label: "AUTHOR (OPTIONAL)",
            placeholder: "Attribution or source",
            text: $viewModel.author
        )
    }

    private func formTextField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.lightText)
                .tracking(0.5)

            TextField(placeholder, text: text)
                .font(.subheadline)
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.borderColor.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                        Text("Submit Content")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.primaryGradientStart, .primaryGradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .encouragementPink.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(!viewModel.isValid || viewModel.isSubmitting)
        .opacity(viewModel.isValid ? 1.0 : 0.6)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func typeIcon(for type: String) -> String {
        switch type {
        case "text": return "text.alignleft"
        case "quiz": return "questionmark.diamond.fill"
        case "qa": return "bubble.left.and.bubble.right.fill"
        default: return "text.alignleft"
        }
    }

    private func typeLabel(for type: String) -> String {
        switch type {
        case "text": return "Text"
        case "quiz": return "Quiz"
        case "qa": return "Q&A"
        default: return "Text"
        }
    }
}

#Preview {
    NavigationStack {
        SubmitContentView()
    }
}
