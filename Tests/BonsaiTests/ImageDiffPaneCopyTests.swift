import XCTest
@testable import Bonsai

final class ImageDiffPaneCopyTests: XCTestCase {
  func testImageDiffPaneTitlesNameComparisonSides() {
    XCTAssertEqual(ImageDiffPaneSide.before.title, "Before")
    XCTAssertEqual(ImageDiffPaneSide.after.title, "After")
  }

  func testMissingImageCopyNamesUnavailableSide() {
    XCTAssertEqual(ImageDiffPaneSide.before.missingTitle, "No previous image")
    XCTAssertEqual(ImageDiffPaneSide.after.missingTitle, "No new image")
  }
}
