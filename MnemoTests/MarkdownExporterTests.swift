import XCTest
@testable import Mnemo

final class MarkdownExporterTests: XCTestCase {
    let exporter = MarkdownExporter()

    func testFilenameIsDeterministic() {
        let memory = makeMemory()
        let name1 = exporter.filename(for: memory)
        let name2 = exporter.filename(for: memory)
        XCTAssertEqual(name1, name2)
    }

    func testFilenameContainsMemoryId() {
        let memory = makeMemory()
        let name = exporter.filename(for: memory)
        XCTAssertTrue(name.contains(String(memory.id.uuidString.prefix(8))))
    }

    func testFilenameEndsWithMd() {
        let memory = makeMemory()
        XCTAssertTrue(exporter.filename(for: memory).hasSuffix(".md"))
    }

    func testMarkdownContainsMemoryId() {
        let memory = makeMemory()
        let md = exporter.markdown(for: memory)
        XCTAssertTrue(md.contains(memory.id.uuidString))
    }

    func testMarkdownContainsMemoryText() {
        let memory = makeMemory()
        let md = exporter.markdown(for: memory)
        XCTAssertTrue(md.contains(memory.text))
    }

    func testMarkdownContainsFrontmatter() {
        let memory = makeMemory()
        let md = exporter.markdown(for: memory)
        XCTAssertTrue(md.hasPrefix("---\n"))
        XCTAssertTrue(md.contains("type:"))
        XCTAssertTrue(md.contains("confidence:"))
    }

    func testMarkdownReasonPresent() {
        let memory = makeMemory()
        let md = exporter.markdown(for: memory)
        XCTAssertTrue(md.contains(memory.reason))
    }

    private func makeMemory() -> ApprovedMemory {
        ApprovedMemory(
            sourceCandidateId: UUID(),
            sourceCaptureId: UUID(),
            type: .learning,
            text: "I learned that unit tests catch regressions.",
            confidence: 0.9,
            reason: "Explicit learning statement."
        )
    }
}
