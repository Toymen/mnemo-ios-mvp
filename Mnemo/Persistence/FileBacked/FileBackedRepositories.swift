import Foundation

// MARK: - Capture Repository

final class FileBackedCaptureRepository: CaptureRepository {
    private let store = JSONStore<Capture>(filename: "captures")

    func save(_ capture: Capture) async throws {
        try await store.save(capture)
    }

    func fetch(id: UUID) async throws -> Capture? {
        try await store.fetch(id: id)
    }

    func fetchAll() async throws -> [Capture] {
        try await store.fetchAll()
    }

    func update(_ capture: Capture) async throws {
        try await store.update(capture)
    }

    func delete(id: UUID) async throws {
        try await store.delete(id: id)
    }

    func preload() async throws {
        try await store.preload()
    }
}

// MARK: - Memory Repository

final class FileBackedMemoryRepository: MemoryRepository {
    private let candidateStore = JSONStore<MemoryCandidate>(filename: "candidates")
    private let memoryStore = JSONStore<ApprovedMemory>(filename: "approved_memories")

    func saveCandidate(_ candidate: MemoryCandidate) async throws {
        try await candidateStore.save(candidate)
    }

    func fetchCandidate(id: UUID) async throws -> MemoryCandidate? {
        try await candidateStore.fetch(id: id)
    }

    func fetchAllCandidates() async throws -> [MemoryCandidate] {
        try await candidateStore.fetchAll()
    }

    func fetchPendingCandidates() async throws -> [MemoryCandidate] {
        let all = try await candidateStore.fetchAll()
        return all.filter { $0.status == .pending }
    }

    func updateCandidate(_ candidate: MemoryCandidate) async throws {
        try await candidateStore.update(candidate)
    }

    func saveApprovedMemory(_ memory: ApprovedMemory) async throws {
        try await memoryStore.save(memory)
    }

    func fetchApprovedMemory(id: UUID) async throws -> ApprovedMemory? {
        try await memoryStore.fetch(id: id)
    }

    func fetchAllApprovedMemories() async throws -> [ApprovedMemory] {
        try await memoryStore.fetchAll()
    }

    func updateApprovedMemory(_ memory: ApprovedMemory) async throws {
        try await memoryStore.update(memory)
    }

    func preload() async throws {
        try await candidateStore.preload()
        try await memoryStore.preload()
    }
}

// MARK: - Project Repository

final class FileBackedProjectRepository: ProjectRepository {
    private let store = JSONStore<Project>(filename: "projects")

    func save(_ project: Project) async throws {
        try await store.save(project)
    }

    func fetch(id: UUID) async throws -> Project? {
        try await store.fetch(id: id)
    }

    func fetchAll() async throws -> [Project] {
        try await store.fetchAll()
    }

    func update(_ project: Project) async throws {
        try await store.update(project)
    }

    func delete(id: UUID) async throws {
        try await store.delete(id: id)
    }

    func preload() async throws {
        try await store.preload()
    }
}
