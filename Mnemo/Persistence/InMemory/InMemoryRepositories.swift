import Foundation

// MARK: - In-Memory (for tests and previews)

actor InMemoryCaptureRepository: CaptureRepository {
    private var items: [UUID: Capture] = [:]

    func save(_ capture: Capture) async throws { items[capture.id] = capture }
    func fetch(id: UUID) async throws -> Capture? { items[id] }
    func fetchAll() async throws -> [Capture] { Array(items.values) }
    func update(_ capture: Capture) async throws { items[capture.id] = capture }
    func delete(id: UUID) async throws { items.removeValue(forKey: id) }
}

actor InMemoryMemoryRepository: MemoryRepository {
    private var candidates: [UUID: MemoryCandidate] = [:]
    private var memories: [UUID: ApprovedMemory] = [:]

    func saveCandidate(_ c: MemoryCandidate) async throws { candidates[c.id] = c }
    func fetchCandidate(id: UUID) async throws -> MemoryCandidate? { candidates[id] }
    func fetchAllCandidates() async throws -> [MemoryCandidate] { Array(candidates.values) }
    func fetchPendingCandidates() async throws -> [MemoryCandidate] {
        candidates.values.filter { $0.status == .pending }
    }
    func updateCandidate(_ c: MemoryCandidate) async throws { candidates[c.id] = c }

    func saveApprovedMemory(_ m: ApprovedMemory) async throws { memories[m.id] = m }
    func fetchApprovedMemory(id: UUID) async throws -> ApprovedMemory? { memories[id] }
    func fetchAllApprovedMemories() async throws -> [ApprovedMemory] { Array(memories.values) }
    func updateApprovedMemory(_ m: ApprovedMemory) async throws { memories[m.id] = m }
}

actor InMemoryProjectRepository: ProjectRepository {
    private var items: [UUID: Project] = [:]

    func save(_ project: Project) async throws { items[project.id] = project }
    func fetch(id: UUID) async throws -> Project? { items[id] }
    func fetchAll() async throws -> [Project] { Array(items.values) }
    func update(_ project: Project) async throws { items[project.id] = project }
    func delete(id: UUID) async throws { items.removeValue(forKey: id) }
}
