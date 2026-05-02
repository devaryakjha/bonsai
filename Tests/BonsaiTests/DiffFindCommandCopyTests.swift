import XCTest
@testable import Bonsai

final class DiffFindCommandCopyTests: XCTestCase {
  func testDiffFindCommandCopyUsesStandardMacShortcuts() {
    XCTAssertEqual(DiffFindCommandCopy.findTitle, "Find in Diff")
    XCTAssertEqual(DiffFindCommandCopy.findNextTitle, "Find Next in Diff")
    XCTAssertEqual(DiffFindCommandCopy.findPreviousTitle, "Find Previous in Diff")
    XCTAssertEqual(DiffFindCommandCopy.findShortcut, "Command-F")
    XCTAssertEqual(DiffFindCommandCopy.findNextShortcut, "Command-G")
    XCTAssertEqual(DiffFindCommandCopy.findPreviousShortcut, "Command-Shift-G")
  }
}
