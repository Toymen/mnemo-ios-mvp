import Foundation
import Observation

@MainActor
@Observable
final class CaptureViewModel {
    var rawText: String = ""
    var isProcessing: Bool = false
    var error: String?
    var recentCaptures: [Capture] = []
    var generatedCandidates: [MemoryCandidate] = []
    var showCandidates: Bool = false

    private let captureRepository: any CaptureRepository
    private let memoryRepository: any MemoryRepository
    private let extractionEngine: any MemoryExtractionEngine

    init(
        captureRepository: any CaptureRepository,
        memoryRepository: any MemoryRepository,
        extractionEngine: any MemoryExtractionEngine
    ) {
        self.captureRepository = captureRepository
        self.memoryRepository = memoryRepository
        self.extractionEngine = extractionEngine
    }

    func submitCapture() async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isProcessing = true
        error = nil
        defer { isProcessing = false }

        do {
            var capture = Capture(rawText: text)
            try await captureRepository.save(capture)

            let context = MemoryContext()
            let candidates = try await extractionEngine.extractCandidates(from: capture, context: context)

            for candidate in candidates {
                try await memoryRepository.saveCandidate(candidate)
            }

            capture.processingStatus = .processed
            capture.createdCandidateIds = candidates.map { $0.id }
            try await captureRepository.update(capture)

            generatedCandidates = candidates
            showCandidates = true
            rawText = ""
            await loadRecent()
        } catch {
            self.error = error.localizedDescription
            if let firstCapture = try? await captureRepository.fetchAll().last {
                var failed = firstCapture
                failed.processingStatus = .failed
                try? await captureRepository.update(failed)
            }
        }
    }

    func loadRecent() async {
        do {
            let all = try await captureRepository.fetchAll()
            recentCaptures = Array(all.sorted { $0.createdAt > $1.createdAt }.prefix(10))
        } catch {
            self.error = error.localizedDescription
        }
    }
}
