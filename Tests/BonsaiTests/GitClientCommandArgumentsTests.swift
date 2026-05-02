import XCTest
@testable import Bonsai

final class GitClientCommandArgumentsTests: XCTestCase {
  func testRepositorySetupAndRefreshReadArgumentsAreStable() {
    let destination = URL(filePath: "/tmp/bonsai clone")

    XCTAssertEqual(GitClient.validateRepositoryArguments(), ["rev-parse", "--show-toplevel"])
    XCTAssertEqual(
      GitClient.cloneRepositoryArguments(remoteURL: "git@example.com:mobile apps/bonsai.git", destination: destination),
      ["clone", "git@example.com:mobile apps/bonsai.git", "/tmp/bonsai clone"]
    )
    XCTAssertEqual(GitClient.initializeRepositoryArguments(), ["init"])
    XCTAssertEqual(GitClient.statusArguments(), ["status", "--porcelain=v1", "--untracked-files=all"])
    XCTAssertEqual(
      GitClient.statusArguments(includeIgnoredFiles: true),
      ["status", "--porcelain=v1", "--untracked-files=all", "--ignored=matching"]
    )
    XCTAssertEqual(GitClient.headVerificationArguments(), ["rev-parse", "--verify", "HEAD"])
    XCTAssertEqual(
      GitClient.commitListArguments(limit: 300),
      [
        "log",
        "--graph",
        "--date=iso-strict",
        "--decorate=short",
        "--pretty=format:%x1f%H%x1f%h%x1f%an%x1f%ae%x1f%ad%x1f%s%x1f%D",
        "-n",
        "300"
      ]
    )
    XCTAssertEqual(
      GitClient.commitArguments(revision: "feature/local branch"),
      [
        "log",
        "--date=iso-strict",
        "--decorate=short",
        "--pretty=format:%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s%x1f%D",
        "-n",
        "1",
        "feature/local branch"
      ]
    )
    XCTAssertEqual(
      GitClient.refsArguments(),
      [
        "for-each-ref",
        "refs/heads",
        "refs/remotes",
        "refs/tags",
        "--format=%(refname)%1f%(objectname:short)%1f%(upstream:short)%1f%(HEAD)%1f%(upstream:track)"
      ]
    )
    XCTAssertEqual(GitClient.remotesArguments(), ["remote", "-v"])
    XCTAssertEqual(GitClient.stashListArguments(), ["stash", "list"])
    XCTAssertEqual(GitClient.submoduleStatusArguments(), ["submodule", "status", "--recursive"])
    XCTAssertEqual(GitClient.worktreeListArguments(), ["worktree", "list", "--porcelain"])
  }

  func testIntegrationReadArgumentsAreStable() {
    XCTAssertEqual(GitClient.lfsVersionArguments(), ["lfs", "version"])
    XCTAssertEqual(GitClient.gitFlowVersionArguments(), ["flow", "version"])
    XCTAssertEqual(GitClient.configValueArguments("commit.gpgsign"), ["config", "--get", "commit.gpgsign"])
    XCTAssertEqual(GitClient.gitPathArguments("rebase-merge"), ["rev-parse", "--git-path", "rebase-merge"])
    XCTAssertEqual(
      GitClient.bisectRefsArguments(),
      [
        "for-each-ref",
        "refs/bisect",
        "--format=%(refname)%1f%(objectname)%1f%(objectname:short)"
      ]
    )
    XCTAssertEqual(GitClient.headRevisionArguments(short: false), ["rev-parse", "HEAD"])
    XCTAssertEqual(GitClient.headRevisionArguments(short: true), ["rev-parse", "--short", "HEAD"])
    XCTAssertEqual(GitClient.lfsFilesArguments(), ["lfs", "ls-files"])
  }

  func testInspectionReadArgumentsPreservePathsAndDiffModes() {
    let commit = GitCommit(
      hash: "abc123456789",
      shortHash: "abc1234",
      authorName: "Bonsai Tests",
      authorEmail: "tests@example.com",
      date: nil,
      subject: "Polish diff",
      decorations: []
    )
    let file = GitChangedFile(status: "R100", path: "Sources/New File.swift", oldPath: "Sources/Old File.swift")
    let entry = statusEntry(path: "Sources/App View.swift", indexStatus: "M", workTreeStatus: " ")
    let stash = GitStash(index: "stash@{2}", branch: "main", message: "WIP on main")

    XCTAssertEqual(GitClient.changedFilesArguments(commit: commit), ["show", "--format=", "--name-status", "abc123456789"])
    XCTAssertEqual(GitClient.changedFilesArguments(stash: stash), ["stash", "show", "--name-status", "stash@{2}"])
    XCTAssertEqual(GitClient.treeEntriesArguments(commit: commit), ["ls-tree", "-z", "abc123456789"])
    XCTAssertEqual(GitClient.treeEntriesArguments(commit: commit, path: "Sources/Bonsai"), ["ls-tree", "-z", "abc123456789:Sources/Bonsai"])
    XCTAssertEqual(GitClient.blobTextArguments(path: "Sources/New File.swift", commit: commit), ["show", "abc123456789:Sources/New File.swift"])
    XCTAssertEqual(
      GitClient.diffForWorkingTreeFileArguments(entry, staged: true, algorithm: .histogram, whitespaceMode: .show),
      [
        "diff",
        "--no-ext-diff",
        "--no-color",
        "--find-renames",
        "--find-copies",
        "--submodule=diff",
        "--indent-heuristic",
        "--diff-algorithm=histogram",
        "--cached",
        "--",
        "Sources/App View.swift"
      ]
    )
    XCTAssertEqual(
      GitClient.diffForCommitFileArguments(file, commit: commit, algorithm: .patience, whitespaceMode: .ignoreChanges),
      [
        "show",
        "--format=",
        "--no-ext-diff",
        "--no-color",
        "--find-renames",
        "--find-copies",
        "--diff-algorithm=patience",
        "--indent-heuristic",
        "--ignore-space-change",
        "abc123456789",
        "--",
        "Sources/New File.swift"
      ]
    )
    XCTAssertEqual(
      GitClient.diffForStashFileArguments(file, stash: stash, algorithm: .minimal, whitespaceMode: .ignoreAll),
      [
        "diff",
        "--no-ext-diff",
        "--no-color",
        "--find-renames",
        "--find-copies",
        "--submodule=diff",
        "--indent-heuristic",
        "--diff-algorithm=minimal",
        "--ignore-all-space",
        "stash@{2}^1",
        "stash@{2}",
        "--",
        "Sources/New File.swift"
      ]
    )
    XCTAssertEqual(
      GitClient.stashPatchArguments(stash, algorithm: .myers, whitespaceMode: .show),
      [
        "stash",
        "show",
        "--patch",
        "--no-color",
        "--find-renames",
        "--find-copies",
        "--include-untracked",
        "--diff-algorithm=myers",
        "stash@{2}"
      ]
    )
  }

  func testInspectionHistoryAndBlobReadArgumentsAreStable() {
    let commit = GitCommit(
      hash: "abc123456789",
      shortHash: "abc1234",
      authorName: "Bonsai Tests",
      authorEmail: "tests@example.com",
      date: nil,
      subject: "Polish diff",
      decorations: []
    )
    let file = GitChangedFile(status: "R100", path: "Sources/New File.swift", oldPath: "Sources/Old File.swift")
    let stash = GitStash(index: "stash@{2}", branch: "main", message: "WIP on main")

    XCTAssertEqual(GitClient.workingTreeImageOldArguments(path: "Assets/Logo.png"), ["show", "HEAD:Assets/Logo.png"])
    XCTAssertEqual(GitClient.workingTreeImageIndexArguments(path: "Assets/Logo.png"), ["show", ":Assets/Logo.png"])
    XCTAssertEqual(GitClient.commitImageOldArguments(file: file, commit: commit), ["show", "abc123456789^:Sources/Old File.swift"])
    XCTAssertEqual(GitClient.commitImageNewArguments(file: file, commit: commit), ["show", "abc123456789:Sources/New File.swift"])
    XCTAssertEqual(GitClient.stashImageOldArguments(file: file, stash: stash), ["show", "stash@{2}^1:Sources/Old File.swift"])
    XCTAssertEqual(GitClient.stashImageNewArguments(file: file, stash: stash), ["show", "stash@{2}:Sources/New File.swift"])
    XCTAssertEqual(GitClient.conflictStageTextArguments(stage: 2, path: "Sources/App View.swift"), ["show", ":2:Sources/App View.swift"])
    XCTAssertEqual(GitClient.reflogArguments(), ["reflog", "--date=iso"])
    XCTAssertEqual(
      GitClient.reflogEntriesArguments(),
      ["log", "-g", "--pretty=format:%H%x1f%h%x1f%gd%x1f%gs%x1f%aI", "-n", "100"]
    )
    XCTAssertEqual(GitClient.blameArguments(path: "Sources/App View.swift"), ["blame", "--line-porcelain", "--", "Sources/App View.swift"])
    XCTAssertEqual(
      GitClient.fileHistoryArguments(path: "Sources/App View.swift"),
      ["log", "--follow", "--date=iso", "--stat", "--", "Sources/App View.swift"]
    )
    XCTAssertEqual(
      GitClient.fileHistoryEntriesArguments(path: "Sources/App View.swift"),
      [
        "log",
        "--follow",
        "--date=iso-strict",
        "--pretty=format:%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s",
        "--name-status",
        "--",
        "Sources/App View.swift"
      ]
    )
    XCTAssertEqual(
      GitClient.lineHistoryEntriesArguments(path: "Sources/App View.swift", startLine: 12, endLine: 18),
      [
        "log",
        "-L",
        "12,18:Sources/App View.swift",
        "--date=iso-strict",
        "--pretty=format:%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s"
      ]
    )
    XCTAssertEqual(
      GitClient.interactiveRebasePlanArguments(count: 10),
      [
        "log",
        "--reverse",
        "--pretty=format:%H%x1f%h%x1f%s",
        "-n",
        "10"
      ]
    )
    XCTAssertEqual(GitClient.rebaseUpstreamVerificationArguments(firstHash: "abc123456789"), ["rev-parse", "--verify", "abc123456789^"])
  }

  func testInteractiveRebaseStartArgumentsRespectUpdateRefsOption() {
    let item = InteractiveRebaseItem(action: .pick, hash: "abc123", shortHash: "abc123", subject: "First")
    let defaultPlan = InteractiveRebasePlan(upstream: "abc123^", items: [item])
    let updateRefsPlan = InteractiveRebasePlan(upstream: "abc123^", items: [item], updateRefs: true)

    XCTAssertEqual(GitClient.startInteractiveRebaseArguments(defaultPlan), ["rebase", "-i", "abc123^"])
    XCTAssertEqual(GitClient.startInteractiveRebaseArguments(updateRefsPlan), ["rebase", "-i", "--update-refs", "abc123^"])
  }

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
    XCTAssertEqual(
      GitClient.renameTagResolveArguments(oldName: "v1.0 candidate"),
      ["rev-parse", "refs/tags/v1.0 candidate"]
    )
    XCTAssertEqual(
      GitClient.renameTagCreateArguments(newName: "v1.1 candidate", object: "abc1234"),
      ["update-ref", "refs/tags/v1.1 candidate", "abc1234", ""]
    )
    XCTAssertEqual(
      GitClient.renameTagDeleteArguments(oldName: "v1.0 candidate"),
      ["update-ref", "-d", "refs/tags/v1.0 candidate"]
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

  func testLFSLockArgumentsPreservePath() {
    XCTAssertEqual(
      GitClient.lfsLockArguments(path: "Assets/Large Logo.png"),
      ["lfs", "lock", "Assets/Large Logo.png"]
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

  func testStageAndUnstageArgumentsPreservePaths() {
    let entry = statusEntry(path: "Sources/App View.swift", indexStatus: " ", workTreeStatus: "M")
    let second = statusEntry(path: "Docs/Release Notes.md", indexStatus: "?", workTreeStatus: "?")

    XCTAssertEqual(
      GitClient.stageArguments(entry),
      ["add", "--", "Sources/App View.swift"]
    )
    XCTAssertEqual(
      GitClient.stageAllArguments([entry, second]),
      ["add", "--all", "--", "Sources/App View.swift", "Docs/Release Notes.md"]
    )
    XCTAssertEqual(
      GitClient.unstageArguments(entry),
      ["restore", "--staged", "--", "Sources/App View.swift"]
    )
  }

  func testUnstageAllArgumentsSwitchForRepositoriesWithoutHead() {
    let entry = statusEntry(path: "Sources/App View.swift", indexStatus: "A", workTreeStatus: " ")
    let second = statusEntry(path: "Docs/Release Notes.md", indexStatus: "A", workTreeStatus: " ")

    XCTAssertEqual(
      GitClient.unstageAllArguments([entry, second], hasHead: true),
      ["restore", "--staged", "--", "Sources/App View.swift", "Docs/Release Notes.md"]
    )
    XCTAssertEqual(
      GitClient.unstageAllArguments([entry, second], hasHead: false),
      ["rm", "--cached", "-r", "--", "Sources/App View.swift", "Docs/Release Notes.md"]
    )
  }

  func testDiscardArgumentsSeparateUntrackedAndTrackedPaths() {
    let untracked = statusEntry(path: "scratch file.txt", indexStatus: "?", workTreeStatus: "?")
    let secondUntracked = statusEntry(path: "notes/todo.txt", indexStatus: "?", workTreeStatus: "?")
    let modified = statusEntry(path: "Sources/App View.swift", indexStatus: " ", workTreeStatus: "M")
    let deleted = statusEntry(path: "Docs/Old Guide.md", indexStatus: " ", workTreeStatus: "D")

    XCTAssertEqual(
      GitClient.discardUntrackedArguments(untracked),
      ["clean", "-f", "--", "scratch file.txt"]
    )
    XCTAssertEqual(
      GitClient.discardUntrackedArguments([untracked, secondUntracked]),
      ["clean", "-f", "--", "scratch file.txt", "notes/todo.txt"]
    )
    XCTAssertEqual(
      GitClient.discardWorktreeArguments(modified),
      ["restore", "--worktree", "--", "Sources/App View.swift"]
    )
    XCTAssertEqual(
      GitClient.discardWorktreeArguments([modified, deleted]),
      ["restore", "--worktree", "--", "Sources/App View.swift", "Docs/Old Guide.md"]
    )
  }

  func testPatchApplicationArgumentsCoverHunksLinesAndFullPatch() {
    XCTAssertEqual(GitClient.stageHunkArguments(), ["apply", "--cached"])
    XCTAssertEqual(GitClient.unstageHunkArguments(), ["apply", "--cached", "--reverse"])
    XCTAssertEqual(GitClient.stageLineChangeArguments(), ["apply", "--cached", "--unidiff-zero"])
    XCTAssertEqual(GitClient.unstageLineChangeArguments(), ["apply", "--cached", "--reverse", "--unidiff-zero"])
    XCTAssertEqual(GitClient.discardHunkArguments(), ["apply", "--reverse"])
    XCTAssertEqual(GitClient.discardLineChangeArguments(), ["apply", "--reverse", "--unidiff-zero"])
    XCTAssertEqual(GitClient.applyPatchArguments(), ["apply"])
  }

  func testCommitAndRepositoryActionArgumentsPreserveMessagesAndFlags() {
    XCTAssertEqual(
      GitClient.commitArguments(message: "Ship polished sidebar", amend: false, sign: false),
      ["commit", "-m", "Ship polished sidebar"]
    )
    XCTAssertEqual(
      GitClient.commitArguments(message: "Ship polished sidebar", amend: true, sign: true),
      ["commit", "-m", "Ship polished sidebar", "--amend", "-S"]
    )
    XCTAssertEqual(GitClient.repositoryActionArguments(.fetch), ["fetch", "--all", "--prune"])
    XCTAssertEqual(GitClient.repositoryActionArguments(.pull), ["pull", "--ff-only"])
    XCTAssertEqual(GitClient.repositoryActionArguments(.push), ["push"])
  }

  func testSigningAndInProgressOperationArguments() {
    XCTAssertEqual(
      GitClient.setCommitSigningArguments(true),
      ["config", "commit.gpgsign", "true"]
    )
    XCTAssertEqual(
      GitClient.setCommitSigningArguments(false),
      ["config", "commit.gpgsign", "false"]
    )
    XCTAssertEqual(
      GitClient.inProgressOperationArguments(.continueOperation, kind: .rebase),
      ["rebase", "--continue"]
    )
    XCTAssertEqual(
      GitClient.inProgressOperationArguments(.skip, kind: .cherryPick),
      ["cherry-pick", "--skip"]
    )
  }

  func testBisectArgumentsPreserveRevisionsAndMarks() {
    XCTAssertEqual(
      GitClient.startBisectArguments(bad: "bad revision", good: "main~10"),
      ["bisect", "start", "bad revision", "main~10"]
    )
    XCTAssertEqual(
      GitClient.markBisectArguments(.good),
      ["bisect", "good"]
    )
    XCTAssertEqual(
      GitClient.markBisectArguments(.skip),
      ["bisect", "skip"]
    )
    XCTAssertEqual(
      GitClient.resetBisectArguments(),
      ["bisect", "reset"]
    )
  }

  func testGitFlowArgumentsPreserveNames() {
    XCTAssertEqual(
      GitClient.initializeGitFlowArguments(),
      ["flow", "init", "-d"]
    )
    XCTAssertEqual(
      GitClient.startGitFlowArguments(kind: .feature, name: "dashboard polish"),
      ["flow", "feature", "start", "dashboard polish"]
    )
    XCTAssertEqual(
      GitClient.finishGitFlowArguments(kind: .release, name: "1.0 candidate"),
      ["flow", "release", "finish", "1.0 candidate"]
    )
  }

  func testConflictResolutionArgumentsPreservePathsAndChoiceOrder() {
    let entry = statusEntry(path: "Sources/App View.swift", indexStatus: "U", workTreeStatus: "U", kind: .conflicted)

    XCTAssertEqual(
      GitClient.resolveConflictArguments(entry, choice: .ours),
      [
        ["checkout", "--ours", "--", "Sources/App View.swift"],
        ["add", "--", "Sources/App View.swift"]
      ]
    )
    XCTAssertEqual(
      GitClient.resolveConflictArguments(entry, choice: .theirs),
      [
        ["checkout", "--theirs", "--", "Sources/App View.swift"],
        ["add", "--", "Sources/App View.swift"]
      ]
    )
    XCTAssertEqual(
      GitClient.resolveConflictArguments(entry, choice: .markResolved),
      [
        ["add", "--", "Sources/App View.swift"]
      ]
    )
  }

  private func statusEntry(
    path: String,
    indexStatus: Character,
    workTreeStatus: Character,
    kind: GitStatusEntry.ChangeKind = .modified
  ) -> GitStatusEntry {
    GitStatusEntry(
      path: path,
      originalPath: nil,
      indexStatus: indexStatus,
      workTreeStatus: workTreeStatus,
      kind: kind
    )
  }
}
