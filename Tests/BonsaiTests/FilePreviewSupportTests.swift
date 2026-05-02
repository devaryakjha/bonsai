import XCTest
@testable import Bonsai

final class FilePreviewSupportTests: XCTestCase {
  func testImagePathDetectionIsCaseInsensitive() {
    XCTAssertTrue(FilePreviewSupport.isImagePath("Assets/Icon.PNG"))
    XCTAssertTrue(FilePreviewSupport.isImagePath("photo.heic"))
    XCTAssertTrue(FilePreviewSupport.isImagePath("diagram.SVG"))
    XCTAssertTrue(FilePreviewSupport.isImagePath("texture.tga"))
    XCTAssertFalse(FilePreviewSupport.isImagePath("Sources/App.swift"))
  }

  func testBinaryDiffDetectionMatchesGitBinaryOutput() {
    XCTAssertTrue(FilePreviewSupport.isBinaryDiff("Binary files a/image.png and b/image.png differ"))
    XCTAssertFalse(FilePreviewSupport.isBinaryDiff("@@ -1 +1 @@\n-old\n+new"))
  }

  func testBinaryDiffDetectionIgnoresSourceTextContainingDiffer() {
    let diff = """
    @@ -1,2 +1,2 @@
    -let message = "values are equal"
    +let message = "values differ"
    """

    XCTAssertFalse(FilePreviewSupport.isBinaryDiff(diff))
  }
}
