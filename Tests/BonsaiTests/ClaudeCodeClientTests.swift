import XCTest
@testable import Bonsai

final class ClaudeCodeClientTests: XCTestCase {
  func testClaudePrintArgumentsUseNonInteractiveBoundedInvocation() {
    XCTAssertEqual(
      ClaudeCodeClient.claudePrintArguments(),
      [
        "--print",
        "--no-session-persistence",
        "--permission-mode",
        "dontAsk",
        "--max-budget-usd",
        "0.25"
      ]
    )
  }

  func testCommitMessagePromptUsesDiffStatAndBoundedStagedDiff() {
    let diff = String(repeating: "+change\n", count: 12_000)
    let prompt = ClaudeCodeClient.commitMessagePrompt(
      diffStat: " Sources/App.swift | 2 +-\n",
      stagedDiff: diff
    )

    XCTAssertTrue(prompt.contains("Sources/App.swift | 2 +-"))
    XCTAssertTrue(prompt.contains("Return only the commit message text."))
    XCTAssertTrue(prompt.contains("[Diff truncated to 60000 characters]"))
    XCTAssertLessThan(prompt.count, diff.count)
  }

  func testNormalizedCommitMessageStripsFencesLabelsAndAttribution() {
    let output = """
    ```text
    Commit message: Polish release packaging

    Add release verifier and documentation.
    Generated with Claude
    Co-Authored-By: Claude <noreply@anthropic.com>
    ```
    """

    XCTAssertEqual(
      ClaudeCodeClient.normalizedCommitMessage(from: output),
      "Polish release packaging\n\nAdd release verifier and documentation."
    )
  }

  func testStagedDiffArgumentsStayReadOnly() {
    XCTAssertEqual(ClaudeCodeClient.stagedDiffStatArguments(), ["diff", "--cached", "--stat"])
    XCTAssertEqual(
      ClaudeCodeClient.stagedDiffArguments(),
      ["diff", "--cached", "--find-renames", "--find-copies", "--"]
    )
  }
}
