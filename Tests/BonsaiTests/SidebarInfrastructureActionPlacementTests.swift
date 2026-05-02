import XCTest
@testable import Bonsai

final class SidebarInfrastructureActionPlacementTests: XCTestCase {
  func testActionDividerOnlyAppearsAfterExistingRows() {
    XCTAssertFalse(SidebarInfrastructureActionPlacement.showsDivider(beforeActionForCount: 0))
    XCTAssertTrue(SidebarInfrastructureActionPlacement.showsDivider(beforeActionForCount: 1))
    XCTAssertTrue(SidebarInfrastructureActionPlacement.showsDivider(beforeActionForCount: 4))
  }
}
