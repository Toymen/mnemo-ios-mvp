import Foundation

final class FileVaultWriter: Sendable {
    let vaultPath: URL
    private let exporter = MarkdownExporter()

    init(vaultPath: URL) {
        self.vaultPath = vaultPath
    }

    func write(_ memory: ApprovedMemory) throws -> String {
        let memoriesDir = vaultPath.appendingPathComponent("Memories")
        try FileManager.default.createDirectory(at: memoriesDir, withIntermediateDirectories: true)

        let filename = exporter.filename(for: memory)
        let fileURL = memoriesDir.appendingPathComponent(filename)

        // Never overwrite a different memory's file
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let existing = try String(contentsOf: fileURL, encoding: .utf8)
            if !existing.contains(memory.id.uuidString) {
                throw VaultError.fileConflict(fileURL.path)
            }
        }

        let content = exporter.markdown(for: memory)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL.path
    }

    func writeProject(_ project: Project) throws {
        let projectsDir = vaultPath.appendingPathComponent("Projects")
        try FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)

        let filename = "\(project.id.uuidString)-\(safeName(project.name)).md"
        let fileURL = projectsDir.appendingPathComponent(filename)

        let content = projectMarkdown(project)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func projectMarkdown(_ project: Project) -> String {
        let learnings = project.learnings.map { "- \($0)" }.joined(separator: "\n")
        return """
        ---
        id: "\(project.id.uuidString)"
        status: "\(project.status.rawValue)"
        created_at: "\(project.createdAt)"
        updated_at: "\(project.updatedAt)"
        ---

        # \(project.name)

        \(project.summary)

        ## Learnings

        \(learnings.isEmpty ? "_None yet._" : learnings)
        """
    }

    private func safeName(_ name: String) -> String {
        name.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(4)
            .joined(separator: "-")
    }
}

enum VaultError: Error, LocalizedError {
    case fileConflict(String)

    var errorDescription: String? {
        switch self {
        case .fileConflict(let path): return "File conflict at \(path). Will not overwrite different memory."
        }
    }
}
