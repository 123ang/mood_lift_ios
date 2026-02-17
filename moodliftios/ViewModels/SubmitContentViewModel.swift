import Foundation

@Observable
class SubmitContentViewModel {
    var contentText = ""
    var question = ""
    var answer = ""
    var optionA = ""
    var optionB = ""
    var optionC = ""
    var optionD = ""
    var correctOption = ""
    var author = ""
    var selectedCategory: ContentCategory = .encouragement
    var contentType: String = "text"  // "text", "quiz", "qa"
    
    var isSubmitting = false
    var errorMessage: String?
    var showSuccess = false
    
    var isValid: Bool {
        switch contentType {
        case "text":
            let contentOk = !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !selectedCategory.rawValue.isEmpty
            if selectedCategory == .inspiration {
                return contentOk && !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return contentOk
        case "quiz":
            return !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !optionA.isEmpty && !optionB.isEmpty
                && !correctOption.isEmpty
        case "qa":
            return !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return false
        }
    }
    
    func submit() async {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        let submission = ContentSubmission(
            contentText: contentType == "text" ? contentText : nil,
            question: contentType != "text" ? question : nil,
            answer: contentType == "qa" ? answer : nil,
            optionA: contentType == "quiz" ? optionA : nil,
            optionB: contentType == "quiz" ? optionB : nil,
            optionC: contentType == "quiz" ? optionC : nil,
            optionD: contentType == "quiz" ? (optionD.isEmpty ? nil : optionD) : nil,
            correctOption: contentType == "quiz" ? correctOption : nil,
            author: author.isEmpty ? nil : author,
            category: selectedCategory.rawValue,
            contentType: contentType
        )
        
        do {
            let item = try await ContentService.shared.submitContent(submission)
            PendingFeedStore.shared.addPending(item)
            MySubmittedContentStore.shared.add(item, submittedByUserId: AuthService.shared.currentUser?.id)
            await AuthService.shared.addPointsForSubmission(Constants.pointsRewardForContentSubmission)
            // Don’t refresh profile here so the +1 point stays visible; backend should also update points_balance when it records the transaction
            showSuccess = true
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetForm() {
        contentText = ""
        question = ""
        answer = ""
        optionA = ""
        optionB = ""
        optionC = ""
        optionD = ""
        correctOption = ""
        author = ""
        contentType = "text"
        selectedCategory = .encouragement
    }

    /// Categories allowed for the current content type. Text = Encouragement + Inspiration; Quiz = Fun Facts; Q&A = Jokes.
    func allowedCategories(for contentType: String) -> [ContentCategory] {
        switch contentType {
        case "text": return [.encouragement, .inspiration]
        case "quiz": return [.facts]
        case "qa": return [.jokes]
        default: return [.encouragement, .inspiration]
        }
    }

    /// Set category to the first allowed when switching content type (call from View).
    func syncCategoryToContentType() {
        let allowed = allowedCategories(for: contentType)
        if !allowed.contains(selectedCategory) {
            selectedCategory = allowed.first ?? .encouragement
        }
    }
}
