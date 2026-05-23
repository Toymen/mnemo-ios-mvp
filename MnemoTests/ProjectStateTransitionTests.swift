import XCTest
@testable import Mnemo

final class ProjectStateTransitionTests: XCTestCase {

    func testActiveCanTransitionToPassive() {
        XCTAssertTrue(ProjectStatus.active.canTransition(to: .passive))
    }

    func testActiveCanTransitionToDormant() {
        XCTAssertTrue(ProjectStatus.active.canTransition(to: .dormant))
    }

    func testActiveCanTransitionToArchived() {
        XCTAssertTrue(ProjectStatus.active.canTransition(to: .archived))
    }

    func testActiveCannotTransitionToItself() {
        XCTAssertFalse(ProjectStatus.active.canTransition(to: .active))
    }

    func testArchivedCanOnlyTransitionToActive() {
        XCTAssertTrue(ProjectStatus.archived.canTransition(to: .active))
        XCTAssertFalse(ProjectStatus.archived.canTransition(to: .passive))
        XCTAssertFalse(ProjectStatus.archived.canTransition(to: .dormant))
    }

    func testDormantCanTransitionToActiveAndPassive() {
        XCTAssertTrue(ProjectStatus.dormant.canTransition(to: .active))
        XCTAssertTrue(ProjectStatus.dormant.canTransition(to: .passive))
        XCTAssertTrue(ProjectStatus.dormant.canTransition(to: .archived))
    }
}
