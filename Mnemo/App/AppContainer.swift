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

    init() {
        let captureRepo = FileBackedCaptureRepository()
        let memoryRepo = FileBackedMemoryRepository()
        let projectRepo = FileBackedProjectRepository()
        let vaultPath = Self.defaultVaultPath()

        self.captureRepository = captureRepo
        self.memoryRepository = memoryRepo
        self.projectRepository = projectRepo
        self.extractionEngine = RuleBasedMemoryExtractionEngine()
        self.approvalService = ApprovalService(
            memoryRepository: memoryRepo,
            captureRepository: captureRepo
        )
        self.markdownExporter = MarkdownExporter()
        self.vaultWriter = FileVaultWriter(vaultPath: vaultPath)
    }

    private static func defaultVaultPath() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("MnemoVault")
    }
}
