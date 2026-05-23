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
    var savedSegmentCount: Int = 0

    private var sessionCandidates: [MemoryCandidate] = []

    let speechRecognizer = SpeechRecognizer()

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

        speechRecognizer.onSilenceSegment = { [weak self] text in
            Task { @MainActor [weak self] in
                await self?.saveIntermediateCapture(text: text)
            }
        }
    }

    func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
            if !speechRecognizer.transcript.isEmpty {
                rawText = speechRecognizer.transcript
            }
        } else {
            error = nil
            rawText = ""
            savedSegmentCount = 0
            sessionCandidates = []
            speechRecognizer.startRecording()
        }
    }

    var canSubmit: Bool {
        if isProcessing { return false }
        if !sessionCandidates.isEmpty { return true }
        if !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if speechRecognizer.isRecording && !speechRecognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        return false
    }

    func submitCapture() async {
        let wasRecording = speechRecognizer.isRecording

        if wasRecording {
            speechRecognizer.stopRecording()
        }

        if rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !speechRecognizer.transcript.isEmpty {
            rawText = speechRecognizer.transcript
        }

        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isVoice = wasRecording || !speechRecognizer.transcript.isEmpty
        let hasSessionCandidates = !sessionCandidates.isEmpty

        guard !text.isEmpty || hasSessionCandidates else { return }

        isProcessing = true
        error = nil
        defer { isProcessing = false }

        var finalCandidates: [MemoryCandidate] = []

        if !text.isEmpty {
            do {
                let transcript: String? = isVoice ? text : nil
                var capture = Capture(
                    inputType: isVoice ? .voice : .text,
                    rawText: text,
                    transcript: transcript
                )
                try await captureRepository.save(capture)

                let context = MemoryContext()
                let candidates = try await extractionEngine.extractCandidates(from: capture, context: context)

                for candidate in candidates {
                    try await memoryRepository.saveCandidate(candidate)
                }

                capture.processingStatus = .processed
                capture.createdCandidateIds = candidates.map { $0.id }
                try await captureRepository.update(capture)

                finalCandidates = candidates
            } catch {
                self.error = error.localizedDescription
                if let firstCapture = try? await captureRepository.fetchAll().last {
                    var failed = firstCapture
                    failed.processingStatus = .failed
                    try? await captureRepository.update(failed)
                }
            }
        }

        generatedCandidates = sessionCandidates + finalCandidates
        sessionCandidates = []
        showCandidates = !generatedCandidates.isEmpty
        rawText = ""
        speechRecognizer.clearTranscript()
        await loadRecent()
    }

    func loadRecent() async {
        do {
            let all = try await captureRepository.fetchAll()
            recentCaptures = Array(all.sorted { $0.createdAt > $1.createdAt }.prefix(10))
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func saveIntermediateCapture(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            var capture = Capture(
                inputType: .voice,
                rawText: trimmed,
                transcript: trimmed
            )
            try await captureRepository.save(capture)

            let context = MemoryContext()
            let candidates = try await extractionEngine.extractCandidates(from: capture, context: context)

            for candidate in candidates {
                try await memoryRepository.saveCandidate(candidate)
            }

            capture.processingStatus = .processed
            capture.createdCandidateIds = candidates.map { $0.id }
            try await captureRepository.update(capture)

            sessionCandidates.append(contentsOf: candidates)
            savedSegmentCount += 1
            await loadRecent()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
