import XCTest
@testable import Bonsai

final class DiffEmptyStateCopyTests: XCTestCase {
  func testDiffEmptyStateCopyIsFactualAndCompact() {
    XCTAssertEqual(DiffEmptyStateCopy.title, "No diff selected")
    XCTAssertEqual(DiffEmptyStateCopy.systemImage, "doc.text.magnifyingglass")
    XCTAssertFalse(DiffEmptyStateCopy.title.localizedCaseInsensitiveContains("choose"))
    XCTAssertFalse(DiffEmptyStateCopy.title.localizedCaseInsensitiveContains("select a"))
  }
}
