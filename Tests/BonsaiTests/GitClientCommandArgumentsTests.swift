import XCTest
@testable import Bonsai

final class GitClientCommandArgumentsTests: XCTestCase {
  func testRemoteManagementArgumentsPreserveNamesAndURLs() {
    XCTAssertEqual(
      GitClient.addRemoteArguments(
        name: "team origin",
        url: "git@example.com:mobile apps/bonsai.git"
      ),
      ["remote", "add", "team origin", "git@example.com:mobile apps/bonsai.git"]
    )
    XCTAssertEqual(
      GitClient.setRemoteURLArguments(
        name: "team origin",
        url: "https://example.com/mobile apps/bonsai.git"
      ),
      ["remote", "set-url", "team origin", "https://example.com/mobile apps/bonsai.git"]
    )
    XCTAssertEqual(
      GitClient.renameRemoteArguments(from: "team origin", to: "upstream mirror"),
      ["remote", "rename", "team origin", "upstream mirror"]
    )
    XCTAssertEqual(
      GitClient.removeRemoteArguments(name: "upstream mirror"),
      ["remote", "remove", "upstream mirror"]
    )
  }

  func testRemoteFetchArgumentsUsePruneByDefault() {
    let remote = GitRemote(
      name: "team origin",
      fetchURL: "git@example.com:mobile apps/bonsai.git",
      pushURL: nil
    )

    XCTAssertEqual(
      GitClient.fetchRemoteArguments(remote),
      ["fetch", "--prune", "team origin"]
    )
    XCTAssertEqual(
      GitClient.pruneRemoteArguments(remote),
      ["remote", "prune", "team origin"]
    )
  }

  func testFetchRemoteBranchArgumentsBuildRefspec() throws {
    let branch = GitRef(
      name: "refs/remotes/origin/feature/sidebar",
      shortName: "origin/feature/sidebar",
      objectName: "abc123",
      isHead: false,
      kind: .remoteBranch
    )

    XCTAssertEqual(
      try GitClient.fetchRemoteBranchArguments(branch),
      ["fetch", "origin", "feature/sidebar:refs/remotes/origin/feature/sidebar"]
    )
  }

  func testFetchRemoteBranchArgumentsRejectPseudoRefs() {
    let branch = GitRef(
      name: "refs/remotes/origin/HEAD",
      shortName: "origin/HEAD",
      objectName: "abc123",
      isHead: false,
      kind: .remoteBranch
    )

    XCTAssertThrowsError(try GitClient.fetchRemoteBranchArguments(branch))
  }

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

  func testStashPushArgumentsPreserveMessageAndUntrackedFlagOrder() {
    XCTAssertEqual(
      GitClient.stashPushArguments(message: nil),
      ["stash", "push"]
    )
    XCTAssertEqual(
      GitClient.stashPushArguments(message: "save local work", includeUntracked: true),
      ["stash", "push", "--include-untracked", "-m", "save local work"]
    )
  }

  func testStashApplyArgumentsSwitchBetweenApplyAndPop() {
    let stash = GitStash(index: "stash@{0}", branch: "main", message: "WIP on main")

    XCTAssertEqual(
      GitClient.stashApplyArguments(stash, pop: false),
      ["stash", "apply", "stash@{0}"]
    )
    XCTAssertEqual(
      GitClient.stashApplyArguments(stash, pop: true),
      ["stash", "pop", "stash@{0}"]
    )
  }

  func testStashDropArgumentsUseStashReference() {
    let stash = GitStash(index: "stash@{1}", branch: "main", message: "WIP on main")

    XCTAssertEqual(
      GitClient.stashDropArguments(stash),
      ["stash", "drop", "stash@{1}"]
    )
  }

  func testStashBranchArgumentsKeepBranchNameAsSingleArgument() {
    let stash = GitStash(index: "stash@{2}", branch: "main", message: "WIP on main")

    XCTAssertEqual(
      GitClient.stashBranchArguments("feature/stashed work", stash: stash),
      ["stash", "branch", "feature/stashed work", "stash@{2}"]
    )
  }

  func testCreateWorktreeArgumentsUseDetachedModeByDefault() {
    XCTAssertEqual(
      GitClient.createWorktreeArguments(
        at: "/tmp/bonsai worktree",
        startPoint: "HEAD"
      ),
      ["worktree", "add", "--detach", "/tmp/bonsai worktree", "HEAD"]
    )
  }

  func testCreateWorktreeArgumentsKeepBranchNameAsSingleArgument() {
    XCTAssertEqual(
      GitClient.createWorktreeArguments(
        at: "/tmp/bonsai worktree",
        startPoint: "main",
        branch: "feature/worktree branch"
      ),
      ["worktree", "add", "-b", "feature/worktree branch", "/tmp/bonsai worktree", "main"]
    )
  }

  func testRemoveWorktreeArgumentsPreserveForceFlagOrder() {
    let worktree = GitWorktree(
      path: "/tmp/bonsai worktree",
      head: "abc1234",
      branch: nil,
      isDetached: true,
      isBare: false,
      isPrunable: false
    )

    XCTAssertEqual(
      GitClient.removeWorktreeArguments(worktree),
      ["worktree", "remove", "/tmp/bonsai worktree"]
    )
    XCTAssertEqual(
      GitClient.removeWorktreeArguments(worktree, force: true),
      ["worktree", "remove", "--force", "/tmp/bonsai worktree"]
    )
  }

  func testPruneWorktreesArgumentsUseGitWorktreePrune() {
    XCTAssertEqual(
      GitClient.pruneWorktreesArguments(),
      ["worktree", "prune"]
    )
  }

  func testUpdateSubmodulesArgumentsUseRecursiveInitUpdate() {
    XCTAssertEqual(
      GitClient.updateSubmodulesArguments(),
      ["submodule", "update", "--init", "--recursive"]
    )
  }

  func testUpdateSubmoduleArgumentsPreservePathSeparator() {
    let submodule = GitSubmodule(
      path: "Vendor/Shared Module",
      commit: "abc1234",
      status: " "
    )

    XCTAssertEqual(
      GitClient.updateSubmoduleArguments(submodule),
      ["submodule", "update", "--init", "--recursive", "--", "Vendor/Shared Module"]
    )
  }

  func testLFSFetchArgumentsUseGitLFSFetch() {
    XCTAssertEqual(
      GitClient.lfsFetchArguments(),
      ["lfs", "fetch"]
    )
  }

  func testLFSPullArgumentsUseGitLFSPull() {
    XCTAssertEqual(
      GitClient.lfsPullArguments(),
      ["lfs", "pull"]
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
