import Foundation
import SwiftUI

/// Persists which Q&A answers are revealed and which quiz answers the user chose,
/// so returning to the same content shows the revealed/chosen state.
@Observable
final class ContentProgressStore {
    static let shared = ContentProgressStore()

    private let revealedQAKey = "content_progress_revealed_qa"
    private let quizAnswersKey = "content_progress_quiz_answers"

    /// Content IDs where the user has revealed the Q&A answer (e.g. jokes).
    private(set) var revealedQAContentIds: Set<String> = [] {
        didSet { saveRevealedQA() }
    }

    /// Map content ID → selected option label ("A", "B", "C", "D") for quiz/Fun Facts.
    private(set) var quizSelectedAnswers: [String: String] = [:] {
        didSet { saveQuizAnswers() }
    }

    private let defaults = UserDefaults.standard

    private init() {
        loadRevealedQA()
        loadQuizAnswers()
    }

    func isRevealed(contentId: String) -> Bool {
        revealedQAContentIds.contains(contentId)
    }

    func revealAnswer(contentId: String) {
        revealedQAContentIds.insert(contentId)
    }

    func selectedQuizAnswer(for contentId: String) -> String? {
        quizSelectedAnswers[contentId]
    }

    func setQuizAnswer(contentId: String, option: String) {
        quizSelectedAnswers[contentId] = option
    }

    private func loadRevealedQA() {
        if let ids = defaults.array(forKey: revealedQAKey) as? [String] {
            revealedQAContentIds = Set(ids)
        }
    }

    private func saveRevealedQA() {
        defaults.set(Array(revealedQAContentIds), forKey: revealedQAKey)
    }

    private func loadQuizAnswers() {
        if let dict = defaults.dictionary(forKey: quizAnswersKey) as? [String: String] {
            quizSelectedAnswers = dict
        }
    }

    private func saveQuizAnswers() {
        defaults.set(quizSelectedAnswers, forKey: quizAnswersKey)
    }
}
