import XCTest
@testable import Mnemo

final class ApprovalInvariantTests: XCTestCase {

    // MARK: - Invariant: Only ApprovalService creates ApprovedMemory

    func testApproveCreatesApprovedMemory() async throws {
        let memRepo = InMemoryMemoryRepository()
        let capRepo = InMemoryCaptureRepository()
        let service = await ApprovalService(memoryRepository: memRepo, captureRepository: capRepo)

        let candidate = MemoryCandidate(
            sourceCaptureId: UUID(),
            topic: "learning",
            proposedText: "I learned Swift concurrency.",
            confidence: 0.9,
            reason: "Explicit learning statement."
        )
        try await memRepo.saveCandidate(candidate)

        let memory = try await service.approve(candidate: candidate)
        XCTAssertEqual(memory.sourceCandidateId, candidate.id)
        XCTAssertEqual(memory.text, "I learned Swift concurrency.")
        XCTAssertEqual(memory.topic, "learning")
    }

    func testApproveWithEditedTextUsesEditedText() async throws {
        let memRepo = InMemoryMemoryRepository()
        let capRepo = InMemoryCaptureRepository()
        let service = await ApprovalService(memoryRepository: memRepo, captureRepository: capRepo)

        let candidate = MemoryCandidate(
            sourceCaptureId: UUID(),
            topic: "preference",
            proposedText: "I prefer dark mode.",
            confidence: 0.8,
            reason: "Preference statement."
        )
        try await memRepo.saveCandidate(candidate)

        let memory = try await service.approve(candidate: candidate, editedText: "I prefer dark mode always.")
        XCTAssertEqual(memory.text, "I prefer dark mode always.")
    }

    func testRejectDoesNotCreateApprovedMemory() async throws {
        let memRepo = InMemoryMemoryRepository()
        let capRepo = InMemoryCaptureRepository()
        let service = await ApprovalService(memoryRepository: memRepo, captureRepository: capRepo)

        let candidate = MemoryCandidate(
            sourceCaptureId: UUID(),
            topic: "general",
            proposedText: "Some text.",
            confidence: 0.5,
            reason: "General."
        )
        try await memRepo.saveCandidate(candidate)
        try await service.reject(candidate: candidate)

        let memories = try await memRepo.fetchAllApprovedMemories()
        XCTAssertTrue(memories.isEmpty)

        let updated = try await memRepo.fetchCandidate(id: candidate.id)
        XCTAssertEqual(updated?.status, .rejected)
    }

    func testApproveNonPendingCandidateThrows() async throws {
        let memRepo = InMemoryMemoryRepository()
        let capRepo = InMemoryCaptureRepository()
        let service = await ApprovalService(memoryRepository: memRepo, captureRepository: capRepo)

        var candidate = MemoryCandidate(
            sourceCaptureId: UUID(),
            topic: "general",
            proposedText: "Some text.",
            confidence: 0.5,
            reason: "General."
        )
        candidate.status = .rejected
        try await memRepo.saveCandidate(candidate)

        do {
            _ = try await service.approve(candidate: candidate)
            XCTFail("Should have thrown")
        } catch ApprovalError.candidateNotPending {
            // expected
        }
    }

    func testApproveEmptyTextThrows() async throws {
        let memRepo = InMemoryMemoryRepository()
        let capRepo = InMemoryCaptureRepository()
        let service = await ApprovalService(memoryRepository: memRepo, captureRepository: capRepo)

        let candidate = MemoryCandidate(
            sourceCaptureId: UUID(),
            topic: "general",
            proposedText: "Some text.",
            confidence: 0.5,
            reason: "General."
        )
        try await memRepo.saveCandidate(candidate)

        do {
            _ = try await service.approve(candidate: candidate, editedText: "   ")
            XCTFail("Should have thrown")
        } catch ApprovalError.invalidState {
            // expected
        }
    }

    func testConfidenceIsClamped() {
        let c = MemoryCandidate(sourceCaptureId: UUID(), topic: "general", proposedText: "x", confidence: 1.5, reason: "r")
        XCTAssertEqual(c.confidence, 1.0)

        let c2 = MemoryCandidate(sourceCaptureId: UUID(), topic: "general", proposedText: "x", confidence: -0.1, reason: "r")
        XCTAssertEqual(c2.confidence, 0.0)
    }
}
