import XCTest
@testable import Bonsai

final class BinaryPreviewCopyTests: XCTestCase {
  func testBinaryPreviewUsesStatusTitle() {
    let copy = BinaryPreviewCopy(isImage: false, statusTitle: "Modified")

    XCTAssertEqual(copy.title, "Binary diff")
    XCTAssertEqual(copy.systemImage, "doc")
    XCTAssertEqual(copy.statusLine, "Modified binary file")
  }

  func testImagePreviewUsesStatusTitle() {
    let copy = BinaryPreviewCopy(isImage: true, statusTitle: "Added")

    XCTAssertEqual(copy.title, "Image diff")
    XCTAssertEqual(copy.systemImage, "photo")
    XCTAssertEqual(copy.statusLine, "Added image file")
  }

  func testMissingStatusUsesShortFallback() {
    XCTAssertEqual(BinaryPreviewCopy(isImage: false, statusTitle: nil).statusLine, "Binary file")
    XCTAssertEqual(BinaryPreviewCopy(isImage: true, statusTitle: " ").statusLine, "Image file")
  }
}
