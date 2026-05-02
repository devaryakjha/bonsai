import XCTest
@testable import Bonsai

final class CodeAgentClientTests: XCTestCase {
  func testClaudePrintArgumentsUseNonInteractiveBoundedInvocation() {
    XCTAssertEqual(
      CodeAgentClient.claudePrintArguments(),
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

  func testCodexExecArgumentsUseReadOnlyNonInteractiveInvocation() {
    XCTAssertEqual(
      CodeAgentClient.codexExecArguments(),
      [
        "exec",
        "--sandbox",
        "read-only",
        "--ask-for-approval",
        "never",
        "--ephemeral",
        "--color",
        "never",
        "-"
      ]
    )
  }

  func testProviderMetadataNamesInstalledCLIs() {
    XCTAssertEqual(CodeAgentProvider.claude.displayName, "Claude Code")
    XCTAssertEqual(CodeAgentProvider.claude.executableName, "claude")
    XCTAssertEqual(CodeAgentProvider.codex.displayName, "Codex CLI")
    XCTAssertEqual(CodeAgentProvider.codex.executableName, "codex")
  }

  func testCommitMessagePromptUsesDiffStatAndBoundedStagedDiff() {
    let diff = String(repeating: "+change\n", count: 12_000)
    let prompt = CodeAgentClient.commitMessagePrompt(
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
      CodeAgentClient.normalizedCommitMessage(from: output),
      "Polish release packaging\n\nAdd release verifier and documentation."
    )
  }

  func testNormalizedCommitMessageStripsCodexAttribution() {
    let output = """
    Commit message: Add provider menu
    Generated with Codex
    """

    XCTAssertEqual(
      CodeAgentClient.normalizedCommitMessage(from: output),
      "Add provider menu"
    )
  }

  func testStagedDiffArgumentsStayReadOnly() {
    XCTAssertEqual(CodeAgentClient.stagedDiffStatArguments(), ["diff", "--cached", "--stat"])
    XCTAssertEqual(
      CodeAgentClient.stagedDiffArguments(),
      ["diff", "--cached", "--find-renames", "--find-copies", "--"]
    )
  }

  func testBranchReviewBaseCandidatesPreferUpstreamAndDedupeFallbacks() {
    let branch = GitRef(
      name: "refs/heads/main",
      shortName: "main",
      objectName: "abc",
      upstream: "origin/main",
      isHead: true,
      kind: .localBranch
    )

    XCTAssertEqual(
      CodeAgentClient.branchReviewBaseCandidates(for: branch),
      ["origin/main", "origin/master", "main", "master"]
    )
  }

  func testBranchReviewArgumentsStayReadOnly() {
    XCTAssertEqual(CodeAgentClient.branchReviewBaseArguments(candidate: "origin/main"), ["merge-base", "HEAD", "origin/main"])
    XCTAssertEqual(CodeAgentClient.branchReviewDiffStatArguments(diffRange: "abc...HEAD"), ["diff", "--stat", "abc...HEAD"])
    XCTAssertEqual(
      CodeAgentClient.branchReviewDiffArguments(diffRange: "abc...HEAD"),
      ["diff", "--find-renames", "--find-copies", "abc...HEAD", "--"]
    )
  }

  func testBranchReviewPromptIncludesBranchBaseAndBoundedDiff() {
    let diff = String(repeating: "+review\n", count: 12_000)
    let prompt = CodeAgentClient.branchReviewPrompt(
      branchName: "feature/review",
      baseReference: "abcdef1",
      diffStat: " Sources/App.swift | 3 +++",
      branchDiff: diff
    )

    XCTAssertTrue(prompt.contains("Branch: feature/review"))
    XCTAssertTrue(prompt.contains("Base: abcdef1"))
    XCTAssertTrue(prompt.contains("Lead with findings ordered by severity."))
    XCTAssertTrue(prompt.contains("[Diff truncated to 60000 characters]"))
    XCTAssertLessThan(prompt.count, diff.count)
  }
}
