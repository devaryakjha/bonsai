import XCTest
@testable import Bonsai

final class GitClientCommandArgumentsTests: XCTestCase {
  func testDeleteRemoteBranchArgumentsUseRemoteAndBranchName() throws {
    let branch = GitRef(
      name: "refs/remotes/origin/feature/sidebar",
      shortName: "origin/feature/sidebar",
      objectName: "abc123",
      isHead: false,
      kind: .remoteBranch
    )

    XCTAssertEqual(
      try GitClient.deleteRemoteBranchArguments(branch),
      ["push", "origin", "--delete", "feature/sidebar"]
    )
  }

  func testDeleteRemoteBranchArgumentsRejectPseudoRefs() {
    let branch = GitRef(
      name: "refs/remotes/origin/HEAD",
      shortName: "origin/HEAD",
      objectName: "abc123",
      isHead: false,
      kind: .remoteBranch
    )

    XCTAssertThrowsError(try GitClient.deleteRemoteBranchArguments(branch))
  }

  func testLFSFetchArgumentsUseGitLFSFetch() {
    XCTAssertEqual(
      GitClient.lfsFetchArguments(),
      ["lfs", "fetch"]
    )
  }

  func testLFSCheckoutArgumentsUseGitLFSCheckout() {
    XCTAssertEqual(
      GitClient.lfsCheckoutArguments(),
      ["lfs", "checkout"]
    )
  }

  func testLFSPruneArgumentsUseGitLFSPrune() {
    XCTAssertEqual(
      GitClient.lfsPruneArguments(),
      ["lfs", "prune"]
    )
  }

  func testLFSUnlockArgumentsPreserveForceFlagOrder() {
    XCTAssertEqual(
      GitClient.lfsUnlockArguments(path: "Assets/logo.png", force: false),
      ["lfs", "unlock", "Assets/logo.png"]
    )
    XCTAssertEqual(
      GitClient.lfsUnlockArguments(path: "Assets/logo.png", force: true),
      ["lfs", "unlock", "--force", "Assets/logo.png"]
    )
  }
}
