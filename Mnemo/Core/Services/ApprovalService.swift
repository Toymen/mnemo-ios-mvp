import Foundation

enum ApprovalError: Error, LocalizedError {
    case candidateNotFound
    case candidateNotPending
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .candidateNotFound: return "Memory candidate not found."
        case .candidateNotPending: return "Candidate is not in pending state."
        case .invalidState(let msg): return msg
        }
    }
}

// ApprovalService is the ONLY code path that creates ApprovedMemory.
// This invariant must never be bypassed.
@MainActor
final class ApprovalService {
    private let memoryRepository: any MemoryRepository
    private let captureRepository: any CaptureRepository

    init(memoryRepository: any MemoryRepository, captureRepository: any CaptureRepository) {
        self.memoryRepository = memoryRepository
        self.captureRepository = captureRepository
    }

    // MARK: - Approve

    func approve(candidate: MemoryCandidate, editedText: String? = nil, projectId: UUID? = nil) async throws -> ApprovedMemory {
        guard candidate.status == .pending || candidate.status == .edited else {
            throw ApprovalError.candidateNotPending
        }
        let finalText = editedText ?? candidate.proposedText
        guard !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ApprovalError.invalidState("Memory text cannot be empty.")
        }

        var updated = candidate
        updated.status = editedText != nil ? .edited : .approved
        try await memoryRepository.updateCandidate(updated)

        let memory = ApprovedMemory(
            sourceCandidateId: candidate.id,
            sourceCaptureId: candidate.sourceCaptureId,
            type: candidate.type,
            text: finalText,
            confidence: candidate.confidence,
            reason: candidate.reason,
            projectId: projectId ?? candidate.suggestedProjectId
        )
        try await memoryRepository.saveApprovedMemory(memory)
        return memory
    }

    // MARK: - Reject

    func reject(candidate: MemoryCandidate) async throws {
        var updated = candidate
        updated.status = .rejected
        try await memoryRepository.updateCandidate(updated)
    }

    // MARK: - Mark Temporary

    func markTemporary(candidate: MemoryCandidate) async throws {
        var updated = candidate
        updated.status = .temporary
        try await memoryRepository.updateCandidate(updated)
    }
}
