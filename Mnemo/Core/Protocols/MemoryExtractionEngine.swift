import Foundation

struct MemoryContext: Sendable {
    let recentMemories: [ApprovedMemory]
    let activeProjects: [Project]
    let userId: String?

    init(recentMemories: [ApprovedMemory] = [], activeProjects: [Project] = [], userId: String? = nil) {
        self.recentMemories = recentMemories
        self.activeProjects = activeProjects
        self.userId = userId
    }
}

protocol MemoryExtractionEngine: Sendable {
    var engineName: String { get }
    func extractCandidates(from capture: Capture, context: MemoryContext) async throws -> [MemoryCandidate]
}
