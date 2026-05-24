import XCTest
@testable import Mnemo

final class RuleBasedMemoryExtractionEngineTests: XCTestCase {
    let engine = RuleBasedMemoryExtractionEngine()

    func testExtractsLearningStatement() async throws {
        let capture = Capture(rawText: "I learned that async/await makes concurrency cleaner.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertFalse(result.candidates.isEmpty)
        XCTAssertTrue(result.candidates.contains { $0.topic == "learning" })
    }

    func testExtractsPreferenceStatement() async throws {
        let capture = Capture(rawText: "I prefer using SwiftUI over UIKit for new projects.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertTrue(result.candidates.contains { $0.topic == "preference" })
    }

    func testExtractsGoalStatement() async throws {
        let capture = Capture(rawText: "I want to focus on shipping the MVP by end of month.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertTrue(result.candidates.contains { $0.topic == "goal" })
    }

    func testExtractsProjectStatement() async throws {
        let capture = Capture(rawText: "I am working on the authentication module.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertTrue(result.candidates.contains { $0.topic == "project" })
    }

    func testDetectsAmbiguousReference() async throws {
        let capture = Capture(rawText: "We need to fix the issue there.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertTrue(result.candidates.contains { $0.topic == "clarification" })
    }

    func testFallsBackToGeneralForUnmatchedText() async throws {
        let capture = Capture(rawText: "Interesting conversation with the team today about the roadmap.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertFalse(result.candidates.isEmpty)
        XCTAssertTrue(result.candidates.allSatisfy { $0.topic == "general" || $0.topic == "clarification" })
    }

    func testEmptyTextProducesNoCandidates() async throws {
        let capture = Capture(rawText: "  ")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertTrue(result.candidates.isEmpty)
    }

    func testCandidateSourceCaptureIdMatches() async throws {
        let capture = Capture(rawText: "I learned something important.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertTrue(result.candidates.allSatisfy { $0.sourceCaptureId == capture.id })
    }

    func testCandidatesHaveNonEmptyProposedText() async throws {
        let capture = Capture(rawText: "I prefer remote work and I learned TypeScript last year.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertTrue(result.candidates.allSatisfy { !$0.proposedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

    func testEnrichedMarkdownIsNilForRuleBased() async throws {
        let capture = Capture(rawText: "I learned Swift concurrency.")
        let result = try await engine.extract(from: capture, context: MemoryContext())
        XCTAssertNil(result.enrichedMarkdown)
    }
}
