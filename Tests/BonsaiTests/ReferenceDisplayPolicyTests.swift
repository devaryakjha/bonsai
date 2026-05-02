import XCTest
@testable import Bonsai

final class ReferenceDisplayPolicyTests: XCTestCase {
  func testReferenceDisplayPolicyCapsDefaultRowsAndReportsHiddenCount() {
    let refs = Array(0..<(ReferenceDisplayPolicy.defaultLimit + 3))

    XCTAssertEqual(
      ReferenceDisplayPolicy.visibleItems(refs, showAll: false),
      Array(refs.prefix(ReferenceDisplayPolicy.defaultLimit))
    )
    XCTAssertEqual(ReferenceDisplayPolicy.hiddenCount(refs, showAll: false), 3)
  }

  func testReferenceDisplayPolicyShowsAllRowsWhenExpanded() {
    let refs = Array(0..<(ReferenceDisplayPolicy.defaultLimit + 3))

    XCTAssertEqual(ReferenceDisplayPolicy.visibleItems(refs, showAll: true), refs)
    XCTAssertEqual(ReferenceDisplayPolicy.hiddenCount(refs, showAll: true), 0)
  }
}
