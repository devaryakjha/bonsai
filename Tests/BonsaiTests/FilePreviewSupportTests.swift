import XCTest
@testable import Bonsai

final class FilePreviewSupportTests: XCTestCase {
  func testImagePathDetectionIsCaseInsensitive() {
    XCTAssertTrue(FilePreviewSupport.isImagePath("Assets/Icon.PNG"))
    XCTAssertTrue(FilePreviewSupport.isImagePath("photo.heic"))
    XCTAssertFalse(FilePreviewSupport.isImagePath("Sources/App.swift"))
  }

  func testBinaryDiffDetectionMatchesGitBinaryOutput() {
    XCTAssertTrue(FilePreviewSupport.isBinaryDiff("Binary files a/image.png and b/image.png differ"))
    XCTAssertFalse(FilePreviewSupport.isBinaryDiff("@@ -1 +1 @@\n-old\n+new"))
  }
}
