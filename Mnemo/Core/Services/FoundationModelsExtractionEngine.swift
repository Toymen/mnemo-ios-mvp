import Foundation
import FoundationModels

@Generable
struct LLMExtractionOutput {
    @Guide(description: "List of distinct memory candidates extracted from the capture. Extract 1–3 candidates maximum.")
    var candidates: [LLMMemoryCandidate]

    @Guide(description: """
    A markdown document enriching the capture. Must include:
    1. A blockquote of the original text.
    2. A mermaid diagram (mindmap or graph TD) that maps the key concepts and their relationships.
    3. A one-paragraph summary.
    Always wrap the diagram in a fenced code block tagged 'mermaid'.
    """)
    var enrichedMarkdown: String
}

@Generable
struct LLMMemoryCandidate {
    @Guide(description: "Free-form topic label for this memory. Use descriptive, lowercase words such as 'coding', 'health', 'career', 'relationships', 'finance', 'learning', 'travel', 'creative'.")
    var topic: String

    @Guide(description: "The key fact or insight to remember, written as a clear, self-contained sentence.")
    var proposedText: String

    @Guide(description: "Confidence that this is worth remembering, from 0.0 (uncertain) to 1.0 (very confident).")
    var confidence: Double

    @Guide(description: "One sentence explaining why this is worth remembering.")
    var reason: String
}

@Generable
struct LLMMarkdownOutput {
    @Guide(description: """
    A complete markdown document with a syntactically valid Mermaid diagram. \
    Use only graph TD or graph LR. Do NOT use mindmap or other diagram types. \
    Wrap the diagram in a fenced code block tagged 'mermaid'. \
    Keep the diagram simple: 3–6 nodes maximum.
    """)
    var markdown: String
}

struct FoundationModelsExtractionEngine: MemoryExtractionEngine {
    let engineName = "Apple Intelligence"
    private let fallback = RuleBasedMemoryExtractionEngine()

    func extract(from capture: Capture, context: MemoryContext) async throws -> ExtractionResult {
        guard SystemLanguageModel.default.isAvailable else {
            return try await fallback.extract(from: capture, context: context)
        }

        let session = LanguageModelSession(instructions: """
            You are a personal memory assistant. Your job is to extract the key insights \
            worth remembering from the user's notes and visualize them clearly.
            Be concise and precise. Never invent facts not present in the note.
            """)

        let prompt = buildPrompt(for: capture)

        do {
            let response = try await session.respond(to: prompt, generating: LLMExtractionOutput.self)
            let output = response.content

            let candidates = output.candidates.map { raw in
                MemoryCandidate(
                    sourceCaptureId: capture.id,
                    topic: raw.topic.trimmingCharacters(in: .whitespacesAndNewlines),
                    proposedText: raw.proposedText.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: max(0, min(1, raw.confidence)),
                    reason: raw.reason.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }.filter { !$0.proposedText.isEmpty && !$0.reason.isEmpty }

            return ExtractionResult(candidates: candidates, enrichedMarkdown: output.enrichedMarkdown)
        } catch {
            return try await fallback.extract(from: capture, context: context)
        }
    }

    private func buildPrompt(for capture: Capture) -> String {
        var prompt = "Extract memory candidates from this personal note:\n\n\"\"\"\n\(capture.effectiveText)\n\"\"\""

        if let recentContext = buildContextHint(for: capture) {
            prompt += "\n\n\(recentContext)"
        }

        return prompt
    }

    private func buildContextHint(for capture: Capture) -> String? {
        nil
    }

    // MARK: - Diagram Retry

    func regenerateMarkdown(for text: String, attempt: Int) async -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }

        let instructions: String
        if attempt == 0 {
            instructions = """
                You are a technical documentation assistant. \
                Generate a markdown document with a syntactically valid Mermaid diagram. \
                Use ONLY graph TD or graph LR. Never use mindmap or other types. \
                Keep diagrams simple: 3–6 nodes, straightforward arrows.
                """
        } else {
            instructions = """
                You are a technical documentation assistant. \
                Previous Mermaid syntax was invalid. Use ONLY this minimal format — no extras:
                graph TD
                    A[Label] --> B[Label]
                    A --> C[Label]
                Do not add subgraphs, styles, classDef, or special characters in labels.
                """
        }

        let session = LanguageModelSession(instructions: instructions)
        let prompt = """
            Generate an enriched markdown document for this note. \
            Include a blockquote of the original text, a valid Mermaid diagram, and a short summary.

            Note: "\(text)"
            """

        do {
            let response = try await session.respond(to: prompt, generating: LLMMarkdownOutput.self)
            return response.content.markdown
        } catch {
            return nil
        }
    }
}
