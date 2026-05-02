import XCTest
@testable import Bonsai

final class SplitDiffRenderedSearchTests: XCTestCase {
  func testRenderedSearchRangesIgnoreGutterLineNumbers() {
    let lines = [
      SplitDiffLine(number: 42, text: "let value = 10")
    ]

    XCTAssertTrue(SplitDiffRenderedSearch.ranges(
      in: lines,
      counterpart: [],
      numberWidth: 3,
      query: "42"
    ).isEmpty)

    XCTAssertEqual(SplitDiffRenderedSearch.ranges(
      in: lines,
      counterpart: [],
      numberWidth: 3,
      query: "value"
    ), [NSRange(location: 12, length: 5)])
  }

  func testRenderedSearchRangesIgnoreMissingSidePlaceholders() {
    let oldLines = [
      SplitDiffLine(number: nil, text: "")
    ]
    let newLines = [
      SplitDiffLine(number: 1, text: "+new value")
    ]

    XCTAssertTrue(SplitDiffRenderedSearch.ranges(
      in: oldLines,
      counterpart: newLines,
      numberWidth: 3,
      query: DiffRenderPolicy.splitPlaceholderText
    ).isEmpty)
  }
}
