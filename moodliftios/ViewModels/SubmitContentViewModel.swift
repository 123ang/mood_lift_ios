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
            return !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !selectedCategory.rawValue.isEmpty
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
            _ = try await ContentService.shared.submitContent(submission)
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
    }
}
