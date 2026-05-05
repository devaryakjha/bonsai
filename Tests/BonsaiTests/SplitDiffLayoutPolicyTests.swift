import XCTest
@testable import Bonsai

final class SplitDiffLayoutPolicyTests: XCTestCase {
  func testSplitDiffStacksBelowReadableSideBySideWidth() {
    XCTAssertFalse(SplitDiffLayoutPolicy.usesSideBySide(width: SplitDiffLayoutPolicy.minimumSideBySideWidth - 1))
    XCTAssertTrue(SplitDiffLayoutPolicy.usesSideBySide(width: SplitDiffLayoutPolicy.minimumSideBySideWidth))
  }

  func testDividerPositionClampsCollapsedSideBySidePanes() {
    XCTAssertEqual(SplitDiffLayoutPolicy.clampedDividerPosition(
      length: 900,
      proposedPosition: 40,
      isSideBySide: true
    ), SplitDiffLayoutPolicy.minimumSideBySidePaneLength)
    XCTAssertEqual(SplitDiffLayoutPolicy.clampedDividerPosition(
      length: 900,
      proposedPosition: 860,
      isSideBySide: true
    ), 900 - SplitDiffLayoutPolicy.minimumSideBySidePaneLength)
  }

  func testDividerPositionKeepsReadableUserResize() {
    XCTAssertEqual(SplitDiffLayoutPolicy.clampedDividerPosition(
      length: 900,
      proposedPosition: 360,
      isSideBySide: true
    ), 360)
    XCTAssertFalse(SplitDiffLayoutPolicy.dividerPositionNeedsRepair(
      length: 900,
      position: 360,
      isSideBySide: true
    ))
  }

  func testDividerPositionFallsBackToCenterWhenContainerIsTooSmallForBothMinimums() {
    XCTAssertEqual(SplitDiffLayoutPolicy.clampedDividerPosition(
      length: 300,
      proposedPosition: 40,
      isSideBySide: false
    ), 150)
  }
}
