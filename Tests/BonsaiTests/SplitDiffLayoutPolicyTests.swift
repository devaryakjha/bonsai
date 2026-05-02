import XCTest
@testable import Bonsai

final class SplitDiffLayoutPolicyTests: XCTestCase {
  func testSplitDiffStacksBelowReadableSideBySideWidth() {
    XCTAssertFalse(SplitDiffLayoutPolicy.usesSideBySide(width: SplitDiffLayoutPolicy.minimumSideBySideWidth - 1))
    XCTAssertTrue(SplitDiffLayoutPolicy.usesSideBySide(width: SplitDiffLayoutPolicy.minimumSideBySideWidth))
  }
}
