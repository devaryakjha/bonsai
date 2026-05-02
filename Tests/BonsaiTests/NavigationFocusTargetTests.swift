import XCTest
@testable import Bonsai

final class NavigationFocusTargetTests: XCTestCase {
  func testTabDestinationMovesBetweenSidebarAndHistory() {
    XCTAssertEqual(NavigationFocusTarget.tabDestination(from: nil), .sidebar)
    XCTAssertEqual(NavigationFocusTarget.tabDestination(from: .sidebar), .history)
    XCTAssertEqual(NavigationFocusTarget.tabDestination(from: .history), .sidebar)
  }
}
