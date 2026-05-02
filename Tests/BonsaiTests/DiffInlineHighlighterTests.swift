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

  func testChangedRangesHighlightSeparateTokenEdits() {
    let old = "let first = oldValue + secondOld"
    let new = "let first = newValue + secondNew"
    let ranges = DiffInlineHighlighter.changedRanges(old: old, new: new)

    XCTAssertEqual(ranges.oldRanges.map { String(old[$0]) }, ["oldValue", "secondOld"])
    XCTAssertEqual(ranges.newRanges.map { String(new[$0]) }, ["newValue", "secondNew"])
  }

  func testChangedRangesFallbackForTooManyTokens() {
    let old = (0...DiffRenderPolicy.maxInlineHighlightTokenCount)
      .map { "a\($0)x" }
      .joined(separator: " ")
    let new = (0...DiffRenderPolicy.maxInlineHighlightTokenCount)
      .map { "b\($0)y" }
      .joined(separator: " ")
    let ranges = DiffInlineHighlighter.changedRanges(old: old, new: new)

    XCTAssertEqual(ranges.oldRanges.count, 1)
    XCTAssertEqual(ranges.newRanges.count, 1)
    XCTAssertEqual(ranges.oldRange.map { String(old[$0]) }, old)
    XCTAssertEqual(ranges.newRange.map { String(new[$0]) }, new)
  }

  func testRenderPolicySkipsInlineHighlightForVeryLongLines() {
    let longLine = String(repeating: "a", count: DiffRenderPolicy.maxInlineComparableLength + 1)

    XCTAssertFalse(DiffRenderPolicy.allowsInlineHighlight(oldLine: longLine, newLine: "short"))
    XCTAssertFalse(DiffRenderPolicy.allowsInlineHighlight(oldLine: "short", newLine: longLine))
  }

  func testRenderPolicySkipsInlineHighlightForVeryLargeDiffs() {
    XCTAssertTrue(
      DiffRenderPolicy.allowsInlineHighlight(
        oldLine: "let title = \"Fork\"",
        newLine: "let title = \"Bonsai\"",
        diffLineCount: DiffRenderPolicy.maxInlineHighlightLineCount
      )
    )
    XCTAssertFalse(
      DiffRenderPolicy.allowsInlineHighlight(
        oldLine: "let title = \"Fork\"",
        newLine: "let title = \"Bonsai\"",
        diffLineCount: DiffRenderPolicy.maxInlineHighlightLineCount + 1
      )
    )
  }

  func testRenderPolicySkipsLineChangeActionsForVeryLargeDiffs() {
    XCTAssertTrue(
      DiffRenderPolicy.allowsLineChangeActions(
        diffLineCount: DiffRenderPolicy.maxLineChangeActionLineCount
      )
    )
    XCTAssertFalse(
      DiffRenderPolicy.allowsLineChangeActions(
        diffLineCount: DiffRenderPolicy.maxLineChangeActionLineCount + 1
      )
    )
  }

  func testRenderPolicyExposesInlineTokenBound() {
    XCTAssertEqual(DiffRenderPolicy.maxInlineHighlightTokenCount, 256)
  }

  func testRenderPolicyBoundsSplitPlaceholderColumns() {
    XCTAssertEqual(DiffRenderPolicy.placeholderColumns(for: "short"), DiffRenderPolicy.minPlaceholderColumns)

    let longLine = String(repeating: "a", count: DiffRenderPolicy.maxPlaceholderColumns + 1_000)
    XCTAssertEqual(DiffRenderPolicy.placeholderColumns(for: longLine), DiffRenderPolicy.maxPlaceholderColumns)
  }

  func testRenderPolicyUsesBoundedSplitPlaceholderText() {
    let shortPlaceholder = DiffRenderPolicy.splitPlaceholder(counterpart: "short")
    XCTAssertTrue(shortPlaceholder.hasPrefix("No line"))
    XCTAssertEqual(shortPlaceholder.count, DiffRenderPolicy.minPlaceholderColumns)

    let longLine = String(repeating: "a", count: DiffRenderPolicy.maxPlaceholderColumns + 1_000)
    let longPlaceholder = DiffRenderPolicy.splitPlaceholder(counterpart: longLine)
    XCTAssertTrue(longPlaceholder.hasPrefix("No line"))
    XCTAssertEqual(longPlaceholder.count, DiffRenderPolicy.maxPlaceholderColumns)
  }
}
