import Foundation

// ApprovedMemory can ONLY be created through ApprovalService.approve(candidate:editedText:).
// No other code path may instantiate this type — this is the core invariant of Mnemo.
struct ApprovedMemory: Identifiable, Codable, Sendable {
    let id: UUID
    let sourceCandidateId: UUID
    let sourceCaptureId: UUID
    let topic: String
    let text: String
    let confidence: Double
    let reason: String
    let createdAt: Date
    var updatedAt: Date
    var projectId: UUID?
    var markdownPath: String?

    // Internal init — use ApprovalService, not this directly
    init(
        id: UUID = UUID(),
        sourceCandidateId: UUID,
        sourceCaptureId: UUID,
        topic: String,
        text: String,
        confidence: Double,
        reason: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        projectId: UUID? = nil,
        markdownPath: String? = nil
    ) {
        self.id = id
        self.sourceCandidateId = sourceCandidateId
        self.sourceCaptureId = sourceCaptureId
        self.topic = topic
        self.text = text
        self.confidence = max(0.0, min(1.0, confidence))
        self.reason = reason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.projectId = projectId
        self.markdownPath = markdownPath
    }
}
