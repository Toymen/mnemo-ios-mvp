import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let captureRepository: any CaptureRepository
    let memoryRepository: any MemoryRepository
    let projectRepository: any ProjectRepository
    let extractionEngine: any MemoryExtractionEngine
    let approvalService: ApprovalService
    let markdownExporter: MarkdownExporter
    let vaultWriter: FileVaultWriter

    @Published private(set) var isReady = false

    private let _captureRepo: FileBackedCaptureRepository
    private let _memoryRepo: FileBackedMemoryRepository
    private let _projectRepo: FileBackedProjectRepository

    init() {
        let captureRepo = FileBackedCaptureRepository()
        let memoryRepo = FileBackedMemoryRepository()
        let projectRepo = FileBackedProjectRepository()
        let vaultPath = Self.defaultVaultPath()

        self._captureRepo = captureRepo
        self._memoryRepo = memoryRepo
        self._projectRepo = projectRepo

        self.captureRepository = captureRepo
        self.memoryRepository = memoryRepo
        self.projectRepository = projectRepo
        self.extractionEngine = FoundationModelsExtractionEngine()
        self.approvalService = ApprovalService(
            memoryRepository: memoryRepo,
            captureRepository: captureRepo
        )
        self.markdownExporter = MarkdownExporter()
        self.vaultWriter = FileVaultWriter(vaultPath: vaultPath)
    }

    func preload() async {
        let start = ContinuousClock.now
        try? await _captureRepo.preload()
        try? await _memoryRepo.preload()
        try? await _projectRepo.preload()
        let elapsed = ContinuousClock.now - start
        let minimum = Duration.milliseconds(600)
        if elapsed < minimum {
            try? await Task.sleep(for: minimum - elapsed)
        }
        isReady = true
    }

    private static func defaultVaultPath() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("MnemoVault")
    }
}
