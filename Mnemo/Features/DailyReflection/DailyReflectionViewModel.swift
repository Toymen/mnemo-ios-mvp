import Foundation
import Observation

@MainActor
@Observable
final class DailyReflectionViewModel {
    var reflection: DailyReflection?
    var isGenerating: Bool = false
    var isSubmitting: Bool = false
    var error: String?
    var didSubmit: Bool = false
    var generatedCandidateCount: Int = 0

    private let captureRepository: any CaptureRepository
    private let memoryRepository: any MemoryRepository
    private let extractionEngine: any MemoryExtractionEngine
    private let questionService = DailyReflectionQuestionService()

    init(
        captureRepository: any CaptureRepository,
        memoryRepository: any MemoryRepository,
        extractionEngine: any MemoryExtractionEngine
    ) {
        self.captureRepository = captureRepository
        self.memoryRepository = memoryRepository
        self.extractionEngine = extractionEngine
    }

    func generateReflection() async {
        isGenerating = true
        defer { isGenerating = false }

        let questions = questionService.generateQuestions(for: Date(), context: MemoryContext())
        reflection = DailyReflection(
            date: Date(),
            questions: questions,
            answers: Array(repeating: "", count: questions.count)
        )
    }

    func submitReflection() async {
        guard var r = reflection else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        error = nil

        let capture = questionService.captureFromAnswers(reflection: r)
        do {
            try await captureRepository.save(capture)
            let context = MemoryContext()
            let result = try await extractionEngine.extract(from: capture, context: context)
            for c in result.candidates { try await memoryRepository.saveCandidate(c) }

            r.createdCandidateIds = result.candidates.map { $0.id }
            reflection = r
            generatedCandidateCount = result.candidates.count
            didSubmit = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
