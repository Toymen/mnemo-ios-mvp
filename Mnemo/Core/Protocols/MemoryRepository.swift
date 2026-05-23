import Foundation

protocol MemoryRepository: Sendable {
    func saveCandidate(_ candidate: MemoryCandidate) async throws
    func fetchCandidate(id: UUID) async throws -> MemoryCandidate?
    func fetchAllCandidates() async throws -> [MemoryCandidate]
    func fetchPendingCandidates() async throws -> [MemoryCandidate]
    func updateCandidate(_ candidate: MemoryCandidate) async throws

    func saveApprovedMemory(_ memory: ApprovedMemory) async throws
    func fetchApprovedMemory(id: UUID) async throws -> ApprovedMemory?
    func fetchAllApprovedMemories() async throws -> [ApprovedMemory]
    func updateApprovedMemory(_ memory: ApprovedMemory) async throws
}
