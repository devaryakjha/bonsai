import XCTest
@testable import Bonsai

final class RecentCommitMessagePreviewTests: XCTestCase {
  func testPreviewUsesFirstNonEmptyLine() {
    let message = "\n\n  Fix repository scanner  \n\nAdd tests"

    XCTAssertEqual(RecentCommitMessagePreview.title(for: message), "Fix repository scanner")
  }

  func testPreviewTruncatesLongMessages() {
    let message = String(repeating: "a", count: RecentCommitMessagePreview.maxLength + 10)
    let title = RecentCommitMessagePreview.title(for: message)

    XCTAssertEqual(title.count, RecentCommitMessagePreview.maxLength)
    XCTAssertTrue(title.hasSuffix("..."))
  }
}
