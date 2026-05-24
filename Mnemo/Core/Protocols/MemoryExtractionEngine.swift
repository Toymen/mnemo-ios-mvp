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

struct ExtractionResult: Sendable {
    let candidates: [MemoryCandidate]
    let enrichedMarkdown: String?

    init(candidates: [MemoryCandidate], enrichedMarkdown: String? = nil) {
        self.candidates = candidates
        self.enrichedMarkdown = enrichedMarkdown
    }
}

protocol MemoryExtractionEngine: Sendable {
    var engineName: String { get }
    func extract(from capture: Capture, context: MemoryContext) async throws -> ExtractionResult
}
