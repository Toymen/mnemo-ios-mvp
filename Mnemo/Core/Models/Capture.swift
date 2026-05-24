import Foundation

enum CaptureInputType: String, Codable, Sendable {
    case text
    case voice
}

enum CaptureProcessingStatus: String, Codable, Sendable {
    case pending
    case processed
    case failed
}

struct Capture: Identifiable, Codable, Sendable {
    let id: UUID
    let createdAt: Date
    let inputType: CaptureInputType
    let rawText: String
    let transcript: String?
    var processingStatus: CaptureProcessingStatus
    var createdCandidateIds: [UUID]
    var enrichedMarkdown: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        inputType: CaptureInputType = .text,
        rawText: String,
        transcript: String? = nil,
        processingStatus: CaptureProcessingStatus = .pending,
        createdCandidateIds: [UUID] = [],
        enrichedMarkdown: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.inputType = inputType
        self.rawText = rawText
        self.transcript = transcript
        self.processingStatus = processingStatus
        self.createdCandidateIds = createdCandidateIds
        self.enrichedMarkdown = enrichedMarkdown
    }

    var effectiveText: String { transcript ?? rawText }
}
