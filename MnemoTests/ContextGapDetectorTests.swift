import XCTest
@testable import Mnemo

final class ContextGapDetectorTests: XCTestCase {
    let detector = ContextGapDetector()

    func testDetectsAmbiguousThere() {
        let gaps = detector.detectGaps(in: "We should fix it there.")
        XCTAssertTrue(gaps.contains("there"))
    }

    func testDetectsAmbiguousIt() {
        let gaps = detector.detectGaps(in: "It needs to be updated.")
        XCTAssertTrue(gaps.contains("it"))
    }

    func testNonAmbiguousTextHasNoGaps() {
        let gaps = detector.detectGaps(in: "I learned Swift generics today.")
        XCTAssertTrue(gaps.isEmpty)
    }

    func testHasAmbiguousReferences() {
        XCTAssertTrue(detector.hasAmbiguousReferences("fix that thing"))
        XCTAssertFalse(detector.hasAmbiguousReferences("I prefer dark mode."))
    }
}
