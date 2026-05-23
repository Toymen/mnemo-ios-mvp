import Foundation

protocol MarkdownExporting: Sendable {
    func markdown(for memory: ApprovedMemory) -> String
    func filename(for memory: ApprovedMemory) -> String
}
