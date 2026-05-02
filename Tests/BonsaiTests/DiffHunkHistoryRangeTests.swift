import XCTest
@testable import Bonsai

final class DiffHunkHistoryRangeTests: XCTestCase {
  func testRangeUsesNewSideHunkRange() {
    let range = DiffHunkHistoryRange.range(fromHeader: "@@ -10,3 +20,4 @@")

    XCTAssertEqual(range, DiffHunkHistoryRange(startLine: 20, endLine: 23))
    XCTAssertEqual(range?.title, "Lines 20-23")
  }

  func testRangeHandlesSingleLineHunks() {
    let range = DiffHunkHistoryRange.range(fromHeader: "@@ -8 +12 @@")

    XCTAssertEqual(range, DiffHunkHistoryRange(startLine: 12, endLine: 12))
    XCTAssertEqual(range?.title, "Line 12")
  }

  func testRangeKeepsDeletedHunksTraceable() {
    let range = DiffHunkHistoryRange.range(fromHeader: "@@ -4,2 +4,0 @@")

    XCTAssertEqual(range, DiffHunkHistoryRange(startLine: 4, endLine: 4))
  }

  func testInvalidHeaderReturnsNil() {
    XCTAssertNil(DiffHunkHistoryRange.range(fromHeader: "not a hunk"))
  }
}
