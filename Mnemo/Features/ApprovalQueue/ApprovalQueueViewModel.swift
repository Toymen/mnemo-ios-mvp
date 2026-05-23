import Foundation
import Observation

@MainActor
@Observable
final class ApprovalQueueViewModel {
    var pendingCandidates: [MemoryCandidate] = []
    var isLoading: Bool = false
    var error: String?

    private let memoryRepository: any MemoryRepository
    private let approvalService: ApprovalService

    init(memoryRepository: any MemoryRepository, approvalService: ApprovalService) {
        self.memoryRepository = memoryRepository
        self.approvalService = approvalService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            pendingCandidates = try await memoryRepository.fetchPendingCandidates()
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func approve(candidate: MemoryCandidate, editedText: String? = nil) async {
        do {
            _ = try await approvalService.approve(candidate: candidate, editedText: editedText)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func reject(candidate: MemoryCandidate) async {
        do {
            try await approvalService.reject(candidate: candidate)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markTemporary(candidate: MemoryCandidate) async {
        do {
            try await approvalService.markTemporary(candidate: candidate)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
