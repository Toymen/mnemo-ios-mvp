import Foundation

struct MockLLMExtractionEngine: MemoryExtractionEngine {
    let engineName = "Mock"
    let stubbedCandidates: [MemoryCandidate]

    init(stubbedCandidates: [MemoryCandidate] = []) {
        self.stubbedCandidates = stubbedCandidates
    }

    func extractCandidates(from capture: Capture, context: MemoryContext) async throws -> [MemoryCandidate] {
        if stubbedCandidates.isEmpty {
            return [
                MemoryCandidate(
                    sourceCaptureId: capture.id,
                    type: .general,
                    proposedText: capture.effectiveText,
                    confidence: 0.7,
                    reason: "Mock extraction."
                )
            ]
        }
        return stubbedCandidates.map { c in
            MemoryCandidate(
                id: c.id,
                sourceCaptureId: capture.id,
                type: c.type,
                proposedText: c.proposedText,
                confidence: c.confidence,
                reason: c.reason
            )
        }
    }
}
