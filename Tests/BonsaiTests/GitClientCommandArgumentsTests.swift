import XCTest
@testable import Bonsai

final class GitClientCommandArgumentsTests: XCTestCase {
  func testBranchPublishAndForcePushArgumentsPreserveRefs() throws {
    let branch = GitRef(
      name: "refs/heads/feature/local branch",
      shortName: "feature/local branch",
      objectName: "abc123",
      upstream: "origin/feature/remote branch",
      ahead: 1,
      isHead: true,
      kind: .localBranch
    )

    XCTAssertEqual(
      GitClient.publishBranchArguments("feature/local branch", remote: "team origin"),
      ["push", "-u", "team origin", "feature/local branch"]
    )
    XCTAssertEqual(
      try GitClient.forcePushWithLeaseArguments(branch),
      ["push", "--force-with-lease", "origin", "feature/local branch:feature/remote branch"]
    )
  }

  func testForcePushArgumentsRejectMissingUpstream() {
    let branch = GitRef(
      name: "refs/heads/feature/local",
      shortName: "feature/local",
      objectName: "abc123",
      isHead: true,
      kind: .localBranch
    )

    XCTAssertThrowsError(try GitClient.forcePushWithLeaseArguments(branch))
  }

  func testPullBranchArgumentsDistinguishCurrentAndNonCurrentBranches() throws {
    let current = GitRef(
      name: "refs/heads/main",
      shortName: "main",
      objectName: "abc123",
      upstream: "origin/main",
      behind: 2,
      isHead: true,
      kind: .localBranch
    )
    let other = GitRef(
      name: "refs/heads/feature/local branch",
      shortName: "feature/local branch",
      objectName: "def456",
      upstream: "origin/feature/remote branch",
      behind: 1,
      isHead: false,
      kind: .localBranch
    )

    XCTAssertEqual(
      try GitClient.pullBranchArguments(current),
      ["pull", "--ff-only"]
    )
    XCTAssertEqual(
      try GitClient.pullBranchArguments(other),
      [
        "fetch",
        "origin",
        "feature/remote branch:refs/remotes/origin/feature/remote branch",
        "feature/remote branch:refs/heads/feature/local branch"
      ]
    )
  }

  func testPullBranchArgumentsRejectMissingUpstreamForNonCurrentBranch() {
    let branch = GitRef(
      name: "refs/heads/feature/local",
      shortName: "feature/local",
      objectName: "abc123",
      isHead: false,
      kind: .localBranch
    )

    XCTAssertThrowsError(try GitClient.pullBranchArguments(branch))
  }

  func testReferenceMergeRebaseAndTagTransferArguments() {
    let ref = GitRef(
      name: "refs/remotes/origin/feature/sidebar",
      shortName: "origin/feature/sidebar",
      objectName: "abc123",
      isHead: false,
      kind: .remoteBranch
    )

    XCTAssertEqual(
      GitClient.mergeReferenceArguments(ref),
      ["merge", "--no-edit", "origin/feature/sidebar"]
    )
    XCTAssertEqual(
      GitClient.rebaseOntoReferenceArguments(ref),
      ["rebase", "origin/feature/sidebar"]
    )
    XCTAssertEqual(
      GitClient.pushTagArguments("v1.0 candidate", remote: "team origin"),
      ["push", "team origin", "v1.0 candidate"]
    )
    XCTAssertEqual(
      GitClient.deleteRemoteTagArguments("v1.0 candidate", remote: "team origin"),
      ["push", "team origin", ":refs/tags/v1.0 candidate"]
    )
  }

  func testBranchArgumentsPreserveNamesAndStartPoints() {
    XCTAssertEqual(
      GitClient.createBranchArguments(named: "feature/local branch", startPoint: nil),
      ["branch", "feature/local branch"]
    )
    XCTAssertEqual(
      GitClient.createBranchArguments(named: "feature/local branch", startPoint: "origin/main"),
      ["branch", "feature/local branch", "origin/main"]
    )
    XCTAssertEqual(
      GitClient.renameBranchArguments(from: "feature/local branch", to: "release/v1 candidate"),
      ["branch", "-m", "feature/local branch", "release/v1 candidate"]
    )
    XCTAssertEqual(
      GitClient.deleteBranchArguments("release/v1 candidate", force: false),
      ["branch", "-d", "release/v1 candidate"]
    )
    XCTAssertEqual(
      GitClient.deleteBranchArguments("release/v1 candidate", force: true),
      ["branch", "-D", "release/v1 candidate"]
    )
  }

  func testTagArgumentsPreserveNamesMessagesAndTargets() {
    XCTAssertEqual(
      GitClient.createTagArguments(named: "v1.0 candidate", target: nil),
      ["tag", "v1.0 candidate"]
    )
    XCTAssertEqual(
      GitClient.createTagArguments(named: "v1.0 candidate", target: "HEAD~1"),
      ["tag", "v1.0 candidate", "HEAD~1"]
    )
    XCTAssertEqual(
      GitClient.createAnnotatedTagArguments(
        named: "v1.0 candidate",
        message: "Release candidate build",
        target: "abc1234"
      ),
      ["tag", "-a", "v1.0 candidate", "-m", "Release candidate build", "abc1234"]
    )
    XCTAssertEqual(
      GitClient.deleteTagArguments("v1.0 candidate"),
      ["tag", "-d", "v1.0 candidate"]
    )
  }

  func testCheckoutUpstreamAndResetArgumentsPreserveRefs() {
    let remoteBranch = GitRef(
      name: "refs/remotes/origin/feature/sidebar",
      shortName: "origin/feature/sidebar",
      objectName: "abc123",
      isHead: false,
      kind: .remoteBranch
    )

    XCTAssertEqual(
      GitClient.checkoutArguments("feature/local branch"),
      ["checkout", "feature/local branch"]
    )
    XCTAssertEqual(
      GitClient.checkoutTrackingRemoteArguments(remoteBranch),
      ["checkout", "--track", "origin/feature/sidebar"]
    )
    XCTAssertEqual(
      GitClient.setUpstreamArguments("origin/feature/sidebar", for: "feature/local branch"),
      ["branch", "--set-upstream-to=origin/feature/sidebar", "feature/local branch"]
    )
    XCTAssertEqual(
      GitClient.unsetUpstreamArguments(for: "feature/local branch"),
      ["branch", "--unset-upstream", "feature/local branch"]
    )
    XCTAssertEqual(
      GitClient.resetArguments(to: "abc1234", mode: .hard),
      ["reset", "--hard", "abc1234"]
    )
  }

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
