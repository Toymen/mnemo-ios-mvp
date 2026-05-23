import Foundation

struct DailyReflectionQuestionService: Sendable {
    static let defaultQuestions: [String] = [
        "What did you work on today?",
        "What did you learn today?",
        "What are you struggling with?",
        "What do you want to focus on tomorrow?",
        "Any decisions or preferences you want to remember?"
    ]

    func generateQuestions(for date: Date, context: MemoryContext) -> [String] {
        var questions = Self.defaultQuestions

        if !context.activeProjects.isEmpty {
            let names = context.activeProjects.prefix(2).map { $0.name }.joined(separator: " or ")
            questions.insert("How is \(names) going?", at: 1)
        }

        return questions
    }

    func captureFromAnswers(reflection: DailyReflection) -> Capture {
        let combined = zip(reflection.questions, reflection.answers)
            .filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { "Q: \($0.0)\nA: \($0.1)" }
            .joined(separator: "\n\n")

        return Capture(
            inputType: .text,
            rawText: combined,
            processingStatus: .pending
        )
    }
}
