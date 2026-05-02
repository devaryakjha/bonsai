import XCTest
@testable import Bonsai

final class PlatformFailureCopyTests: XCTestCase {
  func testPlatformFailureTitlesUseSentenceCase() {
    XCTAssertEqual(PlatformFailureCopy.openFileTitle, "Open file")
    XCTAssertEqual(PlatformFailureCopy.openInTerminalTitle, "Open in terminal")
    XCTAssertFalse(PlatformFailureCopy.openFileTitle.contains("Open File"))
    XCTAssertFalse(PlatformFailureCopy.openInTerminalTitle.contains("Open in Terminal"))
  }
}
