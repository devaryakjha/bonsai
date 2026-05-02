import XCTest
@testable import Bonsai

final class CommandResultPresentationTests: XCTestCase {
  func testCommandResultSummaryUsesConciseFallbacks() {
    XCTAssertEqual(
      CommandResult(title: "Stage", output: "", isError: false).summary,
      "Completed"
    )
    XCTAssertEqual(
      CommandResult(title: "Stage", output: " \n\t", isError: true).summary,
      "Failed"
    )
  }

  func testCommandResultSummaryUsesFirstOutputLine() {
    let result = CommandResult(
      title: "Fetch origin",
      output: "From github.com:example/bonsai\n * branch main -> FETCH_HEAD",
      isError: false
    )

    XCTAssertEqual(result.summary, "From github.com:example/bonsai")
  }

  func testCommandResultFallbackCopyHasNoTrailingPunctuation() {
    XCTAssertEqual(CommandResult.completedOutput, "Completed")
    XCTAssertEqual(CommandResult.noOutput, "No output")
  }
}
