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

  func testGitCommandOutputFormatterKeepsQuietOutputUnchanged() {
    let output = ProcessOutput(stdout: "Updated\n", stderr: "", exitCode: 0)

    XCTAssertEqual(
      GitCommandOutputFormatter.formattedOutput(arguments: ["pull"], output: output, verbose: false),
      "Updated"
    )
  }

  func testGitCommandOutputFormatterPrependsVerboseCommand() {
    let output = ProcessOutput(stdout: "", stderr: "Deleted branch feature/stale\n", exitCode: 0)

    XCTAssertEqual(
      GitCommandOutputFormatter.formattedOutput(
        arguments: ["branch", "-D", "feature/stale"],
        output: output,
        verbose: true
      ),
      "git branch -D feature/stale\nDeleted branch feature/stale"
    )
  }

  func testGitCommandOutputFormatterQuotesReadableArgumentsWithSpaces() {
    let output = ProcessOutput(stdout: "", stderr: "", exitCode: 0)

    XCTAssertEqual(
      GitCommandOutputFormatter.formattedOutput(
        arguments: ["branch", "-m", "feature/local branch", "release/v1"],
        output: output,
        verbose: true
      ),
      "git branch -m 'feature/local branch' release/v1"
    )
  }
}
