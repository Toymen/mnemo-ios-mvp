import XCTest
@testable import Mnemo

final class DailyReflectionQuestionServiceTests: XCTestCase {
    let service = DailyReflectionQuestionService()

    func testDefaultQuestionsAreNonEmpty() {
        let questions = service.generateQuestions(for: Date(), context: MemoryContext())
        XCTAssertFalse(questions.isEmpty)
    }

    func testQuestionsIncludeActiveProjects() {
        let project = Project(name: "Mnemo MVP", status: .active)
        let context = MemoryContext(activeProjects: [project])
        let questions = service.generateQuestions(for: Date(), context: context)
        XCTAssertTrue(questions.contains { $0.contains("Mnemo MVP") })
    }

    func testCaptureFromAnswersCombinesQuestionsAndAnswers() {
        var reflection = DailyReflection(
            questions: ["What did you learn?", "What's next?"],
            answers: ["Swift actors", "Ship the MVP"]
        )
        let capture = service.captureFromAnswers(reflection: reflection)
        XCTAssertTrue(capture.rawText.contains("What did you learn?"))
        XCTAssertTrue(capture.rawText.contains("Swift actors"))
        XCTAssertEqual(capture.inputType, .text)
    }

    func testCaptureFromAnswersSkipsEmptyAnswers() {
        let reflection = DailyReflection(
            questions: ["Q1", "Q2"],
            answers: ["Answer one", ""]
        )
        let capture = service.captureFromAnswers(reflection: reflection)
        XCTAssertTrue(capture.rawText.contains("Q1"))
        XCTAssertFalse(capture.rawText.contains("Q2"))
    }
}
