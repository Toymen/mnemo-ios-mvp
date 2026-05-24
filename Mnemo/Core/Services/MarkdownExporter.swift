import Foundation

struct MarkdownExporter: MarkdownExporting {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func markdown(for memory: ApprovedMemory) -> String {
        let created = Self.isoFormatter.string(from: memory.createdAt)
        let updated = Self.isoFormatter.string(from: memory.updatedAt)
        let projectId = memory.projectId?.uuidString ?? ""

        return """
        ---
        id: "\(memory.id.uuidString)"
        topic: "\(memory.topic)"
        created_at: "\(created)"
        updated_at: "\(updated)"
        source_capture_id: "\(memory.sourceCaptureId.uuidString)"
        source_candidate_id: "\(memory.sourceCandidateId.uuidString)"
        confidence: \(String(format: "%.2f", memory.confidence))
        project_id: "\(projectId)"
        tags:
          - mnemo
          - memory
          - \(memory.topic)
        ---

        # \(titleSlug(from: memory.text))

        ## Memory

        \(memory.text)

        ## Reason

        \(memory.reason)

        ## Source

        Capture: \(memory.sourceCaptureId.uuidString)
        """
    }

    func filename(for memory: ApprovedMemory) -> String {
        let dateStr = Self.isoFormatter.string(from: memory.createdAt)
            .prefix(10)
        let slug = titleSlug(from: memory.text)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(5)
            .joined(separator: "-")
        return "\(dateStr)-\(memory.id.uuidString.prefix(8))-\(slug).md"
    }

    private func titleSlug(from text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= 60 { return cleaned }
        return String(cleaned.prefix(57)) + "..."
    }
}
