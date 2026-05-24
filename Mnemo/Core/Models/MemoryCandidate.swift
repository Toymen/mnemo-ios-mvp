import Foundation

enum CandidateStatus: String, Codable, Sendable {
    case pending
    case approved
    case rejected
    case edited
    case temporary
}

struct MemoryCandidate: Identifiable, Codable, Sendable {
    let id: UUID
    let sourceCaptureId: UUID
    let topic: String
    let proposedText: String
    let confidence: Double
    let reason: String
    let createdAt: Date
    var status: CandidateStatus
    let suggestedProjectId: UUID?
    let clarificationQuestion: String?

    init(
        id: UUID = UUID(),
        sourceCaptureId: UUID,
        topic: String,
        proposedText: String,
        confidence: Double,
        reason: String,
        createdAt: Date = Date(),
        status: CandidateStatus = .pending,
        suggestedProjectId: UUID? = nil,
        clarificationQuestion: String? = nil
    ) {
        self.id = id
        self.sourceCaptureId = sourceCaptureId
        self.topic = topic
        self.proposedText = proposedText
        self.confidence = max(0.0, min(1.0, confidence))
        self.reason = reason
        self.createdAt = createdAt
        self.status = status
        self.suggestedProjectId = suggestedProjectId
        self.clarificationQuestion = clarificationQuestion
    }
}
