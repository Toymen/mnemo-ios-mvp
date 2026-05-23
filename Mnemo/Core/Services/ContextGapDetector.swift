import Foundation

struct ContextGapDetector: Sendable {
    static let ambiguousTerms: [String] = [
        "there", "that project", "the issue", "that thing",
        "the problem", "the feature", "it", "that one", "here",
        "the bug", "the task", "that idea"
    ]

    func detectGaps(in text: String) -> [String] {
        let lower = text.lowercased()
        return Self.ambiguousTerms.filter { lower.contains($0) }
    }

    func hasAmbiguousReferences(_ text: String) -> Bool {
        !detectGaps(in: text).isEmpty
    }

    func clarificationQuestion(for term: String) -> String {
        "Could you clarify what \"\(term)\" refers to?"
    }
}
