import XCTest
@testable import Mnemo

final class RuleBasedMemoryExtractionEngineTests: XCTestCase {
    let engine = RuleBasedMemoryExtractionEngine()

    func testExtractsLearningStatement() async throws {
        let capture = Capture(rawText: "I learned that async/await makes concurrency cleaner.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.contains { $0.type == .learning })
    }

    func testExtractsPreferenceStatement() async throws {
        let capture = Capture(rawText: "I prefer using SwiftUI over UIKit for new projects.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertTrue(candidates.contains { $0.type == .preference })
    }

    func testExtractsGoalStatement() async throws {
        let capture = Capture(rawText: "I want to focus on shipping the MVP by end of month.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertTrue(candidates.contains { $0.type == .goal })
    }

    func testExtractsProjectStatement() async throws {
        let capture = Capture(rawText: "I am working on the authentication module.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertTrue(candidates.contains { $0.type == .project })
    }

    func testDetectsAmbiguousReference() async throws {
        let capture = Capture(rawText: "We need to fix the issue there.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertTrue(candidates.contains { $0.type == .clarificationNeeded })
    }

    func testFallsBackToGeneralForShortUnmatchedText() async throws {
        let capture = Capture(rawText: "Interesting conversation with the team today about the roadmap.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.allSatisfy { $0.type == .general || $0.type == .clarificationNeeded })
    }

    func testEmptyTextProducesNoGeneral() async throws {
        let capture = Capture(rawText: "  ")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertTrue(candidates.isEmpty)
    }

    func testCandidateSourceCaptureIdMatches() async throws {
        let capture = Capture(rawText: "I learned something important.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertTrue(candidates.allSatisfy { $0.sourceCaptureId == capture.id })
    }

    func testCandidatesHaveNonEmptyProposedText() async throws {
        let capture = Capture(rawText: "I prefer remote work and I learned TypeScript last year.")
        let candidates = try await engine.extractCandidates(from: capture, context: MemoryContext())
        XCTAssertTrue(candidates.allSatisfy { !$0.proposedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
}
