import XCTest
@testable import Bonsai

final class DiffInlineHighlighterTests: XCTestCase {
  func testChangedRangesTrimCommonPrefixAndSuffix() throws {
    let old = "let title = \"Fork\""
    let new = "let title = \"Bonsai\""
    let ranges = DiffInlineHighlighter.changedRanges(
      old: old,
      new: new
    )

    let oldRange = try XCTUnwrap(ranges.oldRange)
    let newRange = try XCTUnwrap(ranges.newRange)
    XCTAssertEqual(String(old[oldRange]), "Fork")
    XCTAssertEqual(String(new[newRange]), "Bonsai")
  }

  func testChangedRangesHandleInsertedToken() throws {
    let old = "git checkout branch"
    let new = "git checkout --track branch"
    let ranges = DiffInlineHighlighter.changedRanges(
      old: old,
      new: new
    )

    XCTAssertNil(ranges.oldRange)
    let newRange = try XCTUnwrap(ranges.newRange)
    XCTAssertEqual(String(new[newRange]), "--track ")
  }

  func testRenderPolicySkipsInlineHighlightForVeryLongLines() {
    let longLine = String(repeating: "a", count: DiffRenderPolicy.maxInlineComparableLength + 1)

    XCTAssertFalse(DiffRenderPolicy.allowsInlineHighlight(oldLine: longLine, newLine: "short"))
    XCTAssertFalse(DiffRenderPolicy.allowsInlineHighlight(oldLine: "short", newLine: longLine))
  }

  func testRenderPolicyBoundsSplitPlaceholderColumns() {
    XCTAssertEqual(DiffRenderPolicy.placeholderColumns(for: "short"), DiffRenderPolicy.minPlaceholderColumns)

    let longLine = String(repeating: "a", count: DiffRenderPolicy.maxPlaceholderColumns + 1_000)
    XCTAssertEqual(DiffRenderPolicy.placeholderColumns(for: longLine), DiffRenderPolicy.maxPlaceholderColumns)
  }
}
