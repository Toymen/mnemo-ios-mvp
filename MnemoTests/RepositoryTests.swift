import XCTest
@testable import Mnemo

final class RepositoryTests: XCTestCase {

    func testInMemoryCaptureRepositorySaveAndFetch() async throws {
        let repo = InMemoryCaptureRepository()
        let capture = Capture(rawText: "Test capture")
        try await repo.save(capture)
        let fetched = try await repo.fetch(id: capture.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.rawText, "Test capture")
    }

    func testInMemoryCaptureRepositoryFetchAll() async throws {
        let repo = InMemoryCaptureRepository()
        try await repo.save(Capture(rawText: "A"))
        try await repo.save(Capture(rawText: "B"))
        let all = try await repo.fetchAll()
        XCTAssertEqual(all.count, 2)
    }

    func testInMemoryMemoryRepositoryPendingCandidates() async throws {
        let repo = InMemoryMemoryRepository()
        var approved = MemoryCandidate(sourceCaptureId: UUID(), type: .goal, proposedText: "x", confidence: 0.9, reason: "r")
        approved.status = .approved
        let pending = MemoryCandidate(sourceCaptureId: UUID(), type: .learning, proposedText: "y", confidence: 0.8, reason: "r")
        try await repo.saveCandidate(approved)
        try await repo.saveCandidate(pending)

        let pending_ = try await repo.fetchPendingCandidates()
        XCTAssertEqual(pending_.count, 1)
        XCTAssertEqual(pending_.first?.status, .pending)
    }

    func testInMemoryProjectRepositorySaveAndFetch() async throws {
        let repo = InMemoryProjectRepository()
        let project = Project(name: "Test Project", status: .active)
        try await repo.save(project)
        let fetched = try await repo.fetch(id: project.id)
        XCTAssertEqual(fetched?.name, "Test Project")
    }

    func testInMemoryProjectRepositoryDelete() async throws {
        let repo = InMemoryProjectRepository()
        let project = Project(name: "Delete Me")
        try await repo.save(project)
        try await repo.delete(id: project.id)
        let fetched = try await repo.fetch(id: project.id)
        XCTAssertNil(fetched)
    }
}
