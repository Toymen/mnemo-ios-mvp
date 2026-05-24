import Foundation

struct RuleBasedMemoryExtractionEngine: MemoryExtractionEngine {
    let engineName = "RuleBased"

    private static let patterns: [(pattern: String, topic: String, confidence: Double, reason: String)] = [
        ("i learned", "learning", 0.85, "Explicit learning statement detected."),
        ("i've learned", "learning", 0.85, "Explicit learning statement detected."),
        ("i realized", "learning", 0.80, "Realization statement detected."),
        ("i discovered", "learning", 0.80, "Discovery statement detected."),
        ("i prefer", "preference", 0.85, "Explicit preference statement detected."),
        ("i don't like", "preference", 0.80, "Preference (negative) statement detected."),
        ("i no longer", "preference", 0.80, "Changed preference statement detected."),
        ("i want to focus on", "goal", 0.85, "Goal statement detected."),
        ("my goal is", "goal", 0.85, "Explicit goal statement detected."),
        ("i'm working on", "project", 0.80, "Active project statement detected."),
        ("i am working on", "project", 0.80, "Active project statement detected."),
        ("i started", "project", 0.75, "Project start statement detected."),
        ("the status of", "status", 0.75, "Status change statement detected."),
        ("is now", "status", 0.70, "State transition statement detected."),
        ("i decided", "decision", 0.80, "Decision statement detected."),
        ("i need to", "task", 0.70, "Need/task statement detected."),
        ("i should", "task", 0.65, "Should statement detected."),
    ]

    private static let ambiguousTerms = ["there", "that project", "the issue", "that thing", "it", "the problem", "the feature"]

    func extract(from capture: Capture, context: MemoryContext) async throws -> ExtractionResult {
        let candidates = extractCandidates(from: capture)
        return ExtractionResult(candidates: candidates, enrichedMarkdown: nil)
    }

    private func extractCandidates(from capture: Capture) -> [MemoryCandidate] {
        let text = capture.effectiveText
        let lower = text.lowercased()
        var candidates: [MemoryCandidate] = []

        for (pattern, topic, confidence, reason) in Self.patterns {
            if lower.contains(pattern) {
                let sentences = extractSentences(containing: pattern, from: text)
                for sentence in sentences {
                    candidates.append(MemoryCandidate(
                        sourceCaptureId: capture.id,
                        topic: topic,
                        proposedText: sentence.trimmingCharacters(in: .whitespacesAndNewlines),
                        confidence: confidence,
                        reason: reason
                    ))
                }
            }
        }

        let ambiguous = detectAmbiguousReferences(in: lower)
        if !ambiguous.isEmpty && candidates.isEmpty {
            candidates.append(MemoryCandidate(
                sourceCaptureId: capture.id,
                topic: "clarification",
                proposedText: text.trimmingCharacters(in: .whitespacesAndNewlines),
                confidence: 0.5,
                reason: "Ambiguous reference detected: \(ambiguous.joined(separator: ", "))",
                clarificationQuestion: "Could you clarify what \"\(ambiguous.first ?? "it")\" refers to?"
            ))
        }

        if candidates.isEmpty && text.count > 20 {
            candidates.append(MemoryCandidate(
                sourceCaptureId: capture.id,
                topic: "general",
                proposedText: text.trimmingCharacters(in: .whitespacesAndNewlines),
                confidence: 0.5,
                reason: "No specific pattern matched; captured as general note."
            ))
        }

        return candidates
    }

    private func extractSentences(containing pattern: String, from text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased().contains(pattern) }
    }

    private func detectAmbiguousReferences(in lower: String) -> [String] {
        Self.ambiguousTerms.filter { lower.contains($0) }
    }
}
