import Foundation

struct DailyReflection: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    var questions: [String]
    var answers: [String]
    var createdCandidateIds: [UUID]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        questions: [String] = [],
        answers: [String] = [],
        createdCandidateIds: [UUID] = []
    ) {
        self.id = id
        self.date = date
        self.questions = questions
        self.answers = answers
        self.createdCandidateIds = createdCandidateIds
    }
}
