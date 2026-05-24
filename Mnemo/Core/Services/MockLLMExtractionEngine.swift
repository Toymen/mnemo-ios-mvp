import Foundation

struct MockLLMExtractionEngine: MemoryExtractionEngine {
    let engineName = "Mock"
    let stubbedCandidates: [MemoryCandidate]

    init(stubbedCandidates: [MemoryCandidate] = []) {
        self.stubbedCandidates = stubbedCandidates
    }

    func extract(from capture: Capture, context: MemoryContext) async throws -> ExtractionResult {
        if stubbedCandidates.isEmpty {
            return ExtractionResult(candidates: [
                MemoryCandidate(
                    sourceCaptureId: capture.id,
                    topic: "general",
                    proposedText: capture.effectiveText,
                    confidence: 0.7,
                    reason: "Mock extraction."
                )
            ])
        }
        let mapped = stubbedCandidates.map { c in
            MemoryCandidate(
                id: c.id,
                sourceCaptureId: capture.id,
                topic: c.topic,
                proposedText: c.proposedText,
                confidence: c.confidence,
                reason: c.reason
            )
        }
        return ExtractionResult(candidates: mapped)
    }
}
