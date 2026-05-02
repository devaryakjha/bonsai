import XCTest
@testable import Bonsai

final class GitParsersTests: XCTestCase {
  func testParseStatusGroupsStagedUnstagedUntrackedAndConflictedFiles() {
    let entries = GitParsers.parseStatus("""
     M Sources/App.swift
    A  README.md
    ?? scratch.txt
    UU Package.swift
    R  Old.swift -> New.swift
    MM Package.resolved
    """)

    XCTAssertEqual(entries.count, 7)
    XCTAssertEqual(entries[0].path, "Sources/App.swift")
    XCTAssertFalse(entries[0].isStaged)
    XCTAssertEqual(entries[1].kind, .added)
    XCTAssertTrue(entries[1].isStaged)
    XCTAssertTrue(entries[2].isUntracked)
    XCTAssertTrue(entries[3].isConflicted)
    XCTAssertEqual(entries[4].originalPath, "Old.swift")
    XCTAssertEqual(entries[4].path, "New.swift")
    XCTAssertTrue(entries[5].isStaged)
    XCTAssertFalse(entries[6].isStaged)
    XCTAssertEqual(entries[5].path, "Package.resolved")
    XCTAssertEqual(entries[6].path, "Package.resolved")
  }

  func testParseRefsClassifiesLocalRemoteAndTagRefs() {
    let refs = GitParsers.parseRefs("""
    refs/heads/main\u{1f}abc123\u{1f}origin/main\u{1f}*\u{1f}[ahead 2, behind 1]
    refs/heads/old\u{1f}bbb222\u{1f}origin/old\u{1f}\u{1f}[gone]
    refs/remotes/origin/main\u{1f}abc123\u{1f}\u{1f}\u{1f}
    refs/tags/v0.1.0\u{1f}def456\u{1f}\u{1f}\u{1f}
    """)

    XCTAssertEqual(refs.count, 4)
    XCTAssertEqual(refs[0].kind, .localBranch)
    XCTAssertTrue(refs[0].isHead)
    XCTAssertEqual(refs[0].upstream, "origin/main")
    XCTAssertEqual(refs[0].ahead, 2)
    XCTAssertEqual(refs[0].behind, 1)
    XCTAssertEqual(refs[0].trackingSummary, "↑ 2 ↓ 1")
    XCTAssertEqual(refs[0].pullTitle, "Pull ↓ 1")
    XCTAssertEqual(refs[0].pushTitle, "Push ↑ 2")
    XCTAssertEqual(refs[0].upstreamRemoteName, "origin")
    XCTAssertEqual(refs[0].upstreamBranchName, "main")
    XCTAssertEqual(refs[1].pullTitle, "Pull")
    XCTAssertEqual(refs[1].pushTitle, "Push")
    XCTAssertTrue(refs[1].upstreamGone)
    XCTAssertEqual(refs[1].trackingSummary, "gone")
    XCTAssertEqual(refs[2].kind, .remoteBranch)
    XCTAssertEqual(refs[3].kind, .tag)
  }

  func testRemoteBranchRefsExposeRemoteAndBranchNames() {
    let branch = GitRef(
      name: "refs/remotes/origin/feature/dashboard",
      shortName: "origin/feature/dashboard",
      objectName: "abc123",
      isHead: false,
      kind: .remoteBranch
    )
    let remoteHead = GitRef(
      name: "refs/remotes/origin/HEAD",
      shortName: "origin/HEAD",
      objectName: "def456",
      isHead: false,
      kind: .remoteBranch
    )
    let localBranch = GitRef(
      name: "refs/heads/main",
      shortName: "main",
      objectName: "fed789",
      isHead: true,
      kind: .localBranch
    )

    XCTAssertEqual(branch.remoteName, "origin")
    XCTAssertEqual(branch.remoteBranchName, "feature/dashboard")
    XCTAssertEqual(branch.remoteTrackingLocalName, "feature/dashboard")
    XCTAssertTrue(branch.isConcreteRemoteBranch)
    XCTAssertNil(remoteHead.remoteName)
    XCTAssertNil(remoteHead.remoteBranchName)
    XCTAssertNil(remoteHead.remoteTrackingLocalName)
    XCTAssertFalse(remoteHead.isConcreteRemoteBranch)
    XCTAssertNil(localBranch.remoteName)
    XCTAssertNil(localBranch.remoteBranchName)
    XCTAssertFalse(localBranch.isConcreteRemoteBranch)
  }

  func testParseCommitsKeepsGraphLaneAndSkipsContinuationRows() {
    let commits = GitParsers.parseCommits("""
    *   \u{1f}abc123456789\u{1f}abc1234\u{1f}Asha\u{1f}asha@example.test\u{1f}2026-05-02T08:50:16+05:30\u{1f}Merge branch\u{1f}HEAD -> main
    |\\
    | * \u{1f}def123456789\u{1f}def1234\u{1f}Asha\u{1f}asha@example.test\u{1f}2026-05-02T08:49:16+05:30\u{1f}Side work\u{1f}side
    """)

    XCTAssertEqual(commits.count, 2)
    XCTAssertEqual(commits[0].graph, "*   ")
    XCTAssertEqual(commits[0].subject, "Merge branch")
    XCTAssertEqual(commits[0].decorations, ["HEAD -> main"])
    XCTAssertEqual(commits[1].graph, "| * ")
  }

  func testParseRemotesMergesFetchAndPushURLs() {
    let remotes = GitParsers.parseRemotes("""
    origin\tgit@github.com:example/bonsai.git (fetch)
    origin\tgit@github.com:example/bonsai.git (push)
    upstream\thttps://github.com/example/upstream.git (fetch)
    """)

    XCTAssertEqual(remotes.count, 2)
    XCTAssertEqual(remotes.first { $0.name == "origin" }?.fetchURL, "git@github.com:example/bonsai.git")
    XCTAssertEqual(remotes.first { $0.name == "origin" }?.pushURL, "git@github.com:example/bonsai.git")
  }

  func testParseTreeEntriesKeepsNamesAndBasePath() {
    let entries = GitParsers.parseTreeEntries(
      "100644 blob abc123\tREADME.md\0" +
      "040000 tree def456\tSources App\0",
      basePath: "Root"
    )

    XCTAssertEqual(entries.count, 2)
    XCTAssertEqual(entries[0].kind, .blob)
    XCTAssertEqual(entries[0].kindTitle, "File")
    XCTAssertEqual(entries[0].name, "README.md")
    XCTAssertEqual(entries[0].path, "Root/README.md")
    XCTAssertTrue(entries[1].isDirectory)
    XCTAssertEqual(entries[1].kindTitle, "Folder")
    XCTAssertEqual(entries[1].path, "Root/Sources App")
    XCTAssertEqual(GitTreeEntry.EntryKind.commit.title, "Submodule")
    XCTAssertEqual(GitTreeEntry.EntryKind.unknown.title, "Unknown")
  }

  func testParseWorktreesReadsBranchAndDetachedEntries() {
    let worktrees = GitParsers.parseWorktrees("""
    worktree /repo/main
    HEAD abc123
    branch refs/heads/main

    worktree /repo/trees/feature
    HEAD def456
    detached
    prunable gitdir file points to non-existent location

    """)

    XCTAssertEqual(worktrees.count, 2)
    XCTAssertEqual(worktrees[0].path, "/repo/main")
    XCTAssertEqual(worktrees[0].displayState, "main")
    XCTAssertFalse(worktrees[0].isDetached)
    XCTAssertEqual(worktrees[1].head, "def456")
    XCTAssertTrue(worktrees[1].isDetached)
    XCTAssertTrue(worktrees[1].isPrunable)
  }

  func testWorktreeDirectoryURLPreservesFullPath() {
    let worktree = GitWorktree(
      path: "/Users/arya/projects/bonsai worktrees/feature",
      head: nil,
      branch: "refs/heads/feature",
      isDetached: false,
      isBare: false,
      isPrunable: false
    )

    XCTAssertEqual(worktree.directoryURL.path(percentEncoded: false), "/Users/arya/projects/bonsai worktrees/feature")
  }

  func testParseSubmodulesKeepsStatusAndReadableState() {
    let submodules = GitParsers.parseSubmodules("""
     abc1234567890abcdef Vendor/Ready (heads/main)
    -def4567890abcdef123 Vendor/Missing
    +fedcba9876543210fed Vendor/Changed
    U1111111111111111111 Vendor/Conflict
    """)

    XCTAssertEqual(submodules.count, 4)
    XCTAssertEqual(submodules[0].path, "Vendor/Ready")
    XCTAssertEqual(submodules[0].statusTitle, "Ready")
    XCTAssertEqual(submodules[0].shortCommit, "abc1234")
    XCTAssertEqual(submodules[1].statusTitle, "Not initialized")
    XCTAssertEqual(submodules[2].statusTitle, "Changed")
    XCTAssertEqual(submodules[3].statusTitle, "Conflicted")
  }

  func testSubmoduleStatusColorTokensHighlightAttentionStates() {
    XCTAssertEqual(
      GitSubmodule(path: "Vendor/Ready", commit: "abc1234", status: " ").statusColorToken,
      .neutral
    )
    XCTAssertEqual(
      GitSubmodule(path: "Vendor/Missing", commit: "abc1234", status: "-").statusColorToken,
      .neutral
    )
    XCTAssertEqual(
      GitSubmodule(path: "Vendor/Changed", commit: "abc1234", status: "+").statusColorToken,
      .amber
    )
    XCTAssertEqual(
      GitSubmodule(path: "Vendor/Conflict", commit: "abc1234", status: "U").statusColorToken,
      .orange
    )
  }

  func testSubmoduleDirectoryURLResolvesRelativeToRepository() {
    let repository = GitRepository(path: "/Users/arya/projects/bonsai app")
    let submodule = GitSubmodule(path: "Vendor/Shared Module", commit: "abc1234", status: " ")

    XCTAssertEqual(
      submodule.directoryURL(in: repository).path(percentEncoded: false),
      "/Users/arya/projects/bonsai app/Vendor/Shared Module"
    )
  }

  func testParseReflogEntriesReadsRecoveryFields() {
    let entries = GitParsers.parseReflogEntries("""
    abcdef1234567890\u{1f}abcdef1\u{1f}HEAD@{0}\u{1f}commit: recover me\u{1f}2026-05-02T08:45:15+05:30
    """)

    XCTAssertEqual(entries.count, 1)
    XCTAssertEqual(entries[0].hash, "abcdef1234567890")
    XCTAssertEqual(entries[0].shortHash, "abcdef1")
    XCTAssertEqual(entries[0].selector, "HEAD@{0}")
    XCTAssertEqual(entries[0].subject, "commit: recover me")
    XCTAssertNotNil(entries[0].date)
  }

  func testParseBlameLinesReadsPorcelainRows() {
    let lines = GitParsers.parseBlameLines("""
    abcdef1234567890abcdef1234567890abcdef12 1 1 1
    author Asha
    author-mail <asha@example.test>
    author-time 1777700000
    author-tz +0530
    summary Initial file
    filename Sources/App.swift
    \tlet title = "Bonsai"
    fedcba9876543210fedcba9876543210fedcba98 3 2 1
    author Nikhil
    author-mail <nikhil@example.test>
    author-time 1777700300
    author-tz +0530
    summary Rename title
    filename Sources/App.swift
    \tlet subtitle = "Git"
    """)

    XCTAssertEqual(lines.count, 2)
    XCTAssertEqual(lines[0].commitHash, "abcdef1234567890abcdef1234567890abcdef12")
    XCTAssertEqual(lines[0].shortHash, "abcdef1")
    XCTAssertEqual(lines[0].author, "Asha")
    XCTAssertEqual(lines[0].authorMail, "asha@example.test")
    XCTAssertEqual(lines[0].originalLine, 1)
    XCTAssertEqual(lines[0].finalLine, 1)
    XCTAssertEqual(lines[0].content, "let title = \"Bonsai\"")
    XCTAssertNotNil(lines[0].authorTime)
    XCTAssertEqual(lines[1].author, "Nikhil")
    XCTAssertEqual(lines[1].originalLine, 3)
    XCTAssertEqual(lines[1].finalLine, 2)
    XCTAssertEqual(lines[1].content, "let subtitle = \"Git\"")
  }

  func testParseFileHistoryEntriesReadsCommitsAndRenames() {
    let entries = GitParsers.parseFileHistoryEntries("""
    \u{1e}abcdef1234567890\u{1f}abcdef1\u{1f}Asha\u{1f}asha@example.test\u{1f}2026-05-02T10:00:00+05:30\u{1f}Update file
    M\tSources/App.swift
    \u{1e}fedcba9876543210\u{1f}fedcba9\u{1f}Nikhil\u{1f}nikhil@example.test\u{1f}2026-05-02T09:00:00+05:30\u{1f}Rename file
    R100\tSources/OldApp.swift\tSources/App.swift
    """)

    XCTAssertEqual(entries.count, 2)
    XCTAssertEqual(entries[0].shortHash, "abcdef1")
    XCTAssertEqual(entries[0].authorName, "Asha")
    XCTAssertEqual(entries[0].subject, "Update file")
    XCTAssertNotNil(entries[0].date)
    XCTAssertEqual(entries[0].changes.first?.status, "M")
    XCTAssertEqual(entries[0].changes.first?.path, "Sources/App.swift")
    XCTAssertEqual(entries[1].changes.first?.status, "R100")
    XCTAssertEqual(entries[1].changes.first?.oldPath, "Sources/OldApp.swift")
    XCTAssertEqual(entries[1].changes.first?.path, "Sources/App.swift")
  }

  func testChangedFileStatusPresentationNormalizesScoredStatuses() {
    let renamed = GitChangedFile(status: "R100", path: "New.swift", oldPath: "Old.swift")
    let copied = GitChangedFile(status: "C75", path: "Copy.swift", oldPath: "Source.swift")
    let modified = GitChangedFile(status: "M", path: "App.swift", oldPath: nil)

    XCTAssertEqual(renamed.statusCode, "R")
    XCTAssertEqual(renamed.statusTitle, "Renamed (R100)")
    XCTAssertEqual(renamed.statusRole, .renamed)
    XCTAssertEqual(copied.statusCode, "C")
    XCTAssertEqual(copied.statusTitle, "Copied (C75)")
    XCTAssertEqual(copied.statusRole, .copied)
    XCTAssertEqual(modified.statusCode, "M")
    XCTAssertEqual(modified.statusTitle, "Modified")
    XCTAssertEqual(modified.statusRole, .modified)
  }

  func testFileHistoryCopyValuesAreStableAndUnique() {
    let entry = GitFileHistoryEntry(
      hash: "abcdef123456",
      shortHash: "abcdef1",
      authorName: "Asha",
      authorEmail: "asha@example.com",
      date: nil,
      subject: "Move sources",
      changes: [
        GitChangedFile(status: "R100", path: "Sources/App.swift", oldPath: "App.swift"),
        GitChangedFile(status: "M", path: "Sources/App.swift", oldPath: nil),
        GitChangedFile(status: "C75", path: "Sources/AppCopy.swift", oldPath: "App.swift")
      ]
    )

    XCTAssertEqual(entry.changedPathsForCopy, "Sources/App.swift\nSources/AppCopy.swift")
    XCTAssertEqual(entry.changedPathCopyCount, 2)
    XCTAssertEqual(entry.previousPathsForCopy, "App.swift")
    XCTAssertEqual(entry.previousPathCopyCount, 1)
  }

  func testBlameLineReferenceUsesFinalLine() {
    let line = GitBlameLine(
      id: 12,
      commitHash: "abcdef123456",
      shortHash: "abcdef1",
      author: "Asha",
      authorMail: "asha@example.com",
      authorTime: nil,
      originalLine: 4,
      finalLine: 12,
      content: "let value = true"
    )

    XCTAssertEqual(line.lineReference(path: "Sources/App.swift"), "Sources/App.swift:12")
  }

  func testStatusEntryPresentationUsesGitStatusLetters() {
    let entries = GitParsers.parseStatus("""
    A  Added.swift
     M Modified.swift
     D Deleted.swift
    UU Conflict.swift
    """)

    XCTAssertEqual(entries.map(\.statusCode), ["A", "M", "D", "U"])
    XCTAssertEqual(entries.map(\.statusTitle), ["Added", "Modified", "Deleted", "Conflicted"])
    XCTAssertEqual(entries.map(\.statusRole), [.added, .modified, .deleted, .conflicted])
  }

  func testChangeStatusRoleFollowsConventionalSemanticColors() {
    XCTAssertEqual(GitChangeStatusRole(code: "A"), .added)
    XCTAssertEqual(GitChangeStatusRole(code: "D"), .deleted)
    XCTAssertEqual(GitChangeStatusRole(code: "M"), .modified)
    XCTAssertEqual(GitChangeStatusRole(code: "T"), .modified)
    XCTAssertEqual(GitChangeStatusRole(code: "R100"), .renamed)
    XCTAssertEqual(GitChangeStatusRole(code: "C75"), .copied)
    XCTAssertEqual(GitChangeStatusRole(code: "U"), .conflicted)
    XCTAssertEqual(GitChangeStatusRole(code: "?"), .untracked)
    XCTAssertEqual(GitChangeStatusRole(code: "X"), .unknown)

    XCTAssertEqual(GitChangeStatusRole(code: "A").colorToken, .green)
    XCTAssertEqual(GitChangeStatusRole(code: "D").colorToken, .red)
    XCTAssertEqual(GitChangeStatusRole(code: "M").colorToken, .amber)
    XCTAssertEqual(GitChangeStatusRole(code: "T").colorToken, .amber)
    XCTAssertEqual(GitChangeStatusRole(code: "R100").colorToken, .purple)
    XCTAssertEqual(GitChangeStatusRole(code: "C75").colorToken, .blue)
    XCTAssertEqual(GitChangeStatusRole(code: "U").colorToken, .orange)
    XCTAssertEqual(GitChangeStatusRole(code: "?").colorToken, .neutral)
    XCTAssertEqual(GitChangeStatusRole(code: "X").colorToken, .neutral)

    XCTAssertEqual(GitChangeStatusRole(code: "A").colorToken.conventionalName, "green")
    XCTAssertEqual(GitChangeStatusRole(code: "D").colorToken.conventionalName, "red")
    XCTAssertEqual(GitChangeStatusRole(code: "M").colorToken.conventionalName, "amber")
  }

  func testRevisionCommandsOwnCopyAndGitSubcommands() {
    XCTAssertEqual(GitRevisionCommand.cherryPick.gitSubcommand, "cherry-pick")
    XCTAssertEqual(GitRevisionCommand.cherryPick.arguments(commitHash: "abc1234"), ["cherry-pick", "--no-edit", "abc1234"])
    XCTAssertEqual(GitRevisionCommand.cherryPick.historyTitle, "Cherry-pick")
    XCTAssertEqual(GitRevisionCommand.cherryPick.selectedCommitTitle, "Cherry-pick selected commit")
    XCTAssertEqual(GitRevisionCommand.cherryPick.resultTitle(shortHash: "abc1234"), "Cherry-pick abc1234")

    XCTAssertEqual(GitRevisionCommand.revert.gitSubcommand, "revert")
    XCTAssertEqual(GitRevisionCommand.revert.arguments(commitHash: "abc1234"), ["revert", "--no-edit", "abc1234"])
    XCTAssertEqual(GitRevisionCommand.revert.historyTitle, "Revert")
    XCTAssertEqual(GitRevisionCommand.revert.selectedCommitTitle, "Revert selected commit")

    XCTAssertEqual(GitRevisionCommand.merge.gitSubcommand, "merge")
    XCTAssertEqual(GitRevisionCommand.merge.arguments(commitHash: "abc1234"), ["merge", "--no-edit", "abc1234"])
    XCTAssertEqual(GitRevisionCommand.merge.historyTitle, "Merge")
    XCTAssertEqual(GitRevisionCommand.merge.selectedCommitTitle, "Merge selected commit")

    XCTAssertEqual(GitRevisionCommand.rebase.gitSubcommand, "rebase")
    XCTAssertEqual(GitRevisionCommand.rebase.arguments(commitHash: "abc1234"), ["rebase", "abc1234"])
    XCTAssertEqual(GitRevisionCommand.rebase.arguments(commitHash: "abc1234", updateRefs: true), ["rebase", "--update-refs", "abc1234"])
    XCTAssertEqual(GitRevisionCommand.merge.arguments(commitHash: "abc1234", updateRefs: true), ["merge", "--no-edit", "abc1234"])
    XCTAssertEqual(GitRevisionCommand.rebase.historyTitle, "Rebase onto")
    XCTAssertEqual(GitRevisionCommand.rebase.selectedCommitTitle, "Rebase onto selected commit")
  }

  func testRevisionCommandRequestCopyNamesCommandAndCommit() {
    let commit = GitCommit(
      hash: "abcdef1234567890",
      shortHash: "abcdef1",
      authorName: "Asha",
      authorEmail: "asha@example.test",
      date: nil,
      subject: "Refactor parser",
      decorations: []
    )

    let cherryPick = RevisionCommandRequest(command: .cherryPick, commit: commit)
    XCTAssertEqual(cherryPick.title, "Cherry-pick selected commit")
    XCTAssertEqual(cherryPick.message, "Cherry-pick abcdef1.")
    XCTAssertEqual(cherryPick.detail, "Refactor parser")
    XCTAssertEqual(cherryPick.primaryActionTitle, "Cherry-pick")

    XCTAssertEqual(RevisionCommandRequest(command: .revert, commit: commit).title, "Revert selected commit")
    XCTAssertEqual(RevisionCommandRequest(command: .merge, commit: commit).primaryActionTitle, "Merge")
    XCTAssertEqual(RevisionCommandRequest(command: .rebase, commit: commit).message, "Rebase onto abcdef1.")
  }

  func testRepositoryFileLocatorBuildsRepositoryRelativeURLs() {
    let repository = GitRepository(path: "/Users/arya/projects/bonsai")
    let url = RepositoryFileLocator.fileURL(repository: repository, path: "Sources/Bonsai/App.swift")

    XCTAssertEqual(RepositoryFileLocator.repositoryURL(repository).path(percentEncoded: false), "/Users/arya/projects/bonsai")
    XCTAssertEqual(url.path(percentEncoded: false), "/Users/arya/projects/bonsai/Sources/Bonsai/App.swift")
    XCTAssertEqual(
      RepositoryFileLocator.filePath(repository: repository, path: "Sources/Bonsai/App.swift"),
      "/Users/arya/projects/bonsai/Sources/Bonsai/App.swift"
    )
  }

  func testGitIgnorePatternIsRepositoryRootRelative() {
    XCTAssertEqual(GitIgnorePattern.repositoryRootPattern(for: "DerivedData/app.log"), "/DerivedData/app.log")
    XCTAssertEqual(GitIgnorePattern.repositoryRootPattern(for: "/DerivedData/app.log"), "/DerivedData/app.log")
    XCTAssertEqual(GitIgnorePattern.repositoryRootPattern(for: "Build Products/app.zip"), "/Build Products/app.zip")
  }

  func testGitIgnorePatternExtractsFileExtensions() {
    XCTAssertEqual(GitIgnorePattern.extensionPattern(for: "DerivedData/app.log"), "*.log")
    XCTAssertEqual(GitIgnorePattern.extensionPattern(for: "Build Products/app.test.zip"), "*.zip")
    XCTAssertEqual(GitIgnorePattern.extensionPattern(for: "Makefile"), nil)
    XCTAssertEqual(GitIgnorePattern.extensionPattern(for: ".env"), nil)
  }

  func testGitIgnorePatternExtractsContainingDirectories() {
    XCTAssertEqual(GitIgnorePattern.directoryPattern(for: "DerivedData/app.log"), "/DerivedData/")
    XCTAssertEqual(GitIgnorePattern.directoryPattern(for: "Build Products/App/app.zip"), "/Build Products/App/")
    XCTAssertEqual(GitIgnorePattern.directoryPattern(for: "/Logs/app.log"), "/Logs/")
    XCTAssertEqual(GitIgnorePattern.directoryPattern(for: "Makefile"), nil)
  }

  func testDeleteRefRequestCopyNamesReferenceKind() {
    let local = GitRef(name: "refs/heads/feature", shortName: "feature", objectName: "abc123", isHead: false, kind: .localBranch)
    let remote = GitRef(name: "refs/remotes/origin/feature", shortName: "origin/feature", objectName: "abc123", isHead: false, kind: .remoteBranch)
    let tag = GitRef(name: "refs/tags/v0.1.0", shortName: "v0.1.0", objectName: "abc123", isHead: false, kind: .tag)

    XCTAssertEqual(DeleteRefRequest(ref: local).title, "Delete branch")
    XCTAssertEqual(DeleteRefRequest(ref: local).message, "Delete local branch feature.")
    XCTAssertTrue(DeleteRefRequest(ref: local).allowsForceDelete)
    XCTAssertEqual(DeleteRefRequest(ref: remote).title, "Delete remote branch")
    XCTAssertEqual(DeleteRefRequest(ref: remote).detail, "The branch reference will be deleted from its remote.")
    XCTAssertFalse(DeleteRefRequest(ref: remote).allowsForceDelete)
    XCTAssertEqual(DeleteRefRequest(ref: tag).title, "Delete tag")
    XCTAssertEqual(DeleteRefRequest(ref: tag).message, "Delete tag v0.1.0.")
    XCTAssertFalse(DeleteRefRequest(ref: tag).allowsForceDelete)
  }

  func testDropStashRequestCopyNamesStashAndMessage() {
    let stash = GitStash(index: "stash@{0}", branch: "main", message: "WIP on main")
    let request = DropStashRequest(stash: stash)

    XCTAssertEqual(request.title, "Drop stash")
    XCTAssertEqual(request.message, "Drop stash@{0}.")
    XCTAssertEqual(request.detail, "WIP on main")
  }

  func testRemoveRemoteRequestCopyNamesRemoteAndURL() {
    let remote = GitRemote(name: "origin", fetchURL: "git@example.com:bonsai.git", pushURL: nil)
    let request = RemoveRemoteRequest(remote: remote)

    XCTAssertEqual(request.title, "Remove remote")
    XCTAssertEqual(request.message, "Remove remote origin.")
    XCTAssertEqual(request.detail, "git@example.com:bonsai.git")
  }

  func testRemoveWorktreeRequestCopyNamesWorktreeAndPath() {
    let worktree = GitWorktree(
      path: "/Users/arya/projects/bonsai-worktree",
      head: "abcdef123456",
      branch: "refs/heads/feature",
      isDetached: false,
      isBare: false,
      isPrunable: false
    )
    let request = RemoveWorktreeRequest(worktree: worktree)

    XCTAssertEqual(request.title, "Remove worktree")
    XCTAssertEqual(request.message, "Remove worktree bonsai-worktree.")
    XCTAssertEqual(request.detail, "/Users/arya/projects/bonsai-worktree")
  }

  func testParseLineHistoryEntriesReadsCommitsAndSkipsPatchBodies() {
    let entries = GitParsers.parseLineHistoryEntries("""
    \u{1e}abcdef1234567890\u{1f}abcdef1\u{1f}Asha\u{1f}asha@example.test\u{1f}2026-05-02T10:00:00+05:30\u{1f}Update line
    diff --git a/Sources/App.swift b/Sources/App.swift
    @@ -2,1 +2,1 @@
    -old
    +new
    """)

    XCTAssertEqual(entries.count, 1)
    XCTAssertEqual(entries[0].shortHash, "abcdef1")
    XCTAssertEqual(entries[0].subject, "Update line")
    XCTAssertTrue(entries[0].changes.isEmpty)
  }

  func testParseDiffHunksReconstructsPatchPerHunk() {
    let hunks = GitParsers.parseDiffHunks("""
    diff --git a/file.txt b/file.txt
    index 1111111..2222222 100644
    --- a/file.txt
    +++ b/file.txt
    @@ -1,3 +1,3 @@
     one
    -two
    +deux
     three
    @@ -10,2 +10,3 @@
     ten
    +eleven
    """)

    XCTAssertEqual(hunks.count, 2)
    XCTAssertTrue(hunks[0].patch.contains("diff --git a/file.txt b/file.txt"))
    XCTAssertTrue(hunks[0].patch.contains("@@ -1,3 +1,3 @@"))
    XCTAssertFalse(hunks[0].patch.contains("@@ -10,2 +10,3 @@"))
    XCTAssertTrue(hunks[1].patch.contains("@@ -10,2 +10,3 @@"))
    XCTAssertTrue(hunks[1].patch.hasSuffix("\n"))
  }

  func testParseDiffLineChangesBuildsZeroContextPatches() throws {
    let hunk = try XCTUnwrap(GitParsers.parseDiffHunks("""
    diff --git a/file.txt b/file.txt
    index 1111111..2222222 100644
    --- a/file.txt
    +++ b/file.txt
    @@ -1,4 +1,5 @@
     one
    -two
    +deux
     three
    +four
    """).first)

    let changes = GitParsers.parseDiffLineChanges(hunk)

    XCTAssertEqual(changes.count, 2)
    XCTAssertEqual(changes[0].kind, .replacement)
    XCTAssertTrue(changes[0].patch.contains("@@ -2,1 +2,1 @@"))
    XCTAssertTrue(changes[0].patch.contains("-two\n+deux"))
    XCTAssertEqual(changes[1].kind, .addition)
    XCTAssertTrue(changes[1].patch.contains("@@ -3,0 +4,1 @@"))
    XCTAssertTrue(changes[1].patch.contains("+four"))
  }

  func testParseSplitDiffSeparatesOldAndNewSides() {
    let split = GitParsers.parseSplitDiff("""
    diff --git a/file.txt b/file.txt
    index 1111111..2222222 100644
    --- a/file.txt
    +++ b/file.txt
    @@ -1,3 +1,3 @@
     one
    -two
    +deux
     three
    """)

    XCTAssertTrue(split.oldText.contains("-two"))
    XCTAssertFalse(split.oldText.contains("+deux"))
    XCTAssertTrue(split.newText.contains("+deux"))
    XCTAssertFalse(split.newText.contains("-two"))
    XCTAssertTrue(split.oldText.contains(" one"))
    XCTAssertTrue(split.newText.contains(" one"))
    XCTAssertEqual(split.oldLines.map(\.number), [nil, 1, 2, 3])
    XCTAssertEqual(split.newLines.map(\.number), [nil, 1, 2, 3])
  }

  func testParseSplitDiffPairsReplacementBlocksAndKeepsLeftoversOneSided() {
    let split = GitParsers.parseSplitDiff("""
    diff --git a/file.txt b/file.txt
    --- a/file.txt
    +++ b/file.txt
    @@ -1,4 +1,5 @@
     one
    -two
    -three
    +deux
    +trois
    +four
     five
    """)

    XCTAssertEqual(split.oldLines.map(\.text), ["@@ -1,4 +1,5 @@", " one", "-two", "-three", "", " five"])
    XCTAssertEqual(split.newLines.map(\.text), ["@@ -1,4 +1,5 @@", " one", "+deux", "+trois", "+four", " five"])
    XCTAssertEqual(split.oldLines.map(\.number), [nil, 1, 2, 3, nil, 4])
    XCTAssertEqual(split.newLines.map(\.number), [nil, 1, 2, 3, 4, 5])
  }

  func testSplitDiffGutterWidthUsesLargestLineNumberAcrossBothSides() {
    let split = SplitDiff(
      oldLines: [
        SplitDiffLine(number: 8, text: " old"),
        SplitDiffLine(number: 9, text: "-old")
      ],
      newLines: [
        SplitDiffLine(number: 1000, text: " new"),
        SplitDiffLine(number: 1001, text: "+new")
      ]
    )

    XCTAssertEqual(split.gutterNumberWidth, 4)
  }

  func testSplitDiffGutterWidthKeepsMinimumForSmallFiles() {
    let split = SplitDiff(
      oldLines: [SplitDiffLine(number: 1, text: " old")],
      newLines: [SplitDiffLine(number: 2, text: " new")]
    )

    XCTAssertEqual(split.gutterNumberWidth, 3)
  }

  func testSplitDiffLinesSeparatePatchMarkersFromDisplayText() {
    let deleted = SplitDiffLine(number: 2, text: "-old value")
    let added = SplitDiffLine(number: 2, text: "+new value")
    let context = SplitDiffLine(number: 1, text: " shared")

    XCTAssertEqual(deleted.changeMarker, "-")
    XCTAssertEqual(deleted.displayText, "old value")
    XCTAssertEqual(added.changeMarker, "+")
    XCTAssertEqual(added.displayText, "new value")
    XCTAssertEqual(context.changeMarker, " ")
    XCTAssertEqual(context.displayText, " shared")
  }

  func testParseSplitDiffKeepsHeaderLikeSourceLines() {
    let split = GitParsers.parseSplitDiff("""
    diff --git a/file.txt b/file.txt
    --- a/file.txt
    +++ b/file.txt
    @@ -1,2 +1,2 @@
    ---flag
    +++flag
     context
    """)

    XCTAssertEqual(split.oldLines.map(\.text), ["@@ -1,2 +1,2 @@", "---flag", " context"])
    XCTAssertEqual(split.newLines.map(\.text), ["@@ -1,2 +1,2 @@", "+++flag", " context"])
    XCTAssertEqual(split.oldLines[1].displayText, "--flag")
    XCTAssertEqual(split.newLines[1].displayText, "++flag")
  }

  func testParseLFSFilesExtractsOidAndPath() {
    let files = GitParsers.parseLFSFiles("""
    2f9c2a4d3b123456 * Assets/image.png
    aaaaa11111 - Fixtures/archive.zip
    """)

    XCTAssertEqual(files.count, 2)
    XCTAssertEqual(files[0].oid, "2f9c2a4d3b123456")
    XCTAssertEqual(files[0].shortOID, "2f9c2a4d3b")
    XCTAssertEqual(files[0].path, "Assets/image.png")
    XCTAssertEqual(files[1].path, "Fixtures/archive.zip")
  }

  func testLFSFileSidebarPresentationUsesPathShortOIDAndFullHelp() {
    let file = GitLFSFile(oid: "2f9c2a4d3b123456", path: "Assets/image.png")

    XCTAssertEqual(file.sidebarTitle, "Assets/image.png")
    XCTAssertEqual(file.sidebarDetail, "2f9c2a4d3b")
    XCTAssertEqual(file.sidebarHelpText, "Path: Assets/image.png\nObject ID: 2f9c2a4d3b123456")
  }

  func testLFSFileURLResolvesRelativeToRepository() {
    let repository = GitRepository(path: "/Users/arya/projects/bonsai app")
    let file = GitLFSFile(oid: "2f9c2a4d3b123456", path: "Assets/Large Image.png")

    XCTAssertEqual(
      file.fileURL(in: repository).path(percentEncoded: false),
      "/Users/arya/projects/bonsai app/Assets/Large Image.png"
    )
  }

  func testGitIgnoreTemplateCatalogHasUniqueUsefulTemplates() {
    let templates = GitIgnoreTemplateCatalog.all
    let ids = templates.map(\.id)

    XCTAssertGreaterThanOrEqual(templates.count, 8)
    XCTAssertEqual(Set(ids).count, ids.count)
    XCTAssertNotNil(GitIgnoreTemplateCatalog.template(id: "macos"))
    XCTAssertNotNil(GitIgnoreTemplateCatalog.template(id: "node"))
    XCTAssertNotNil(GitIgnoreTemplateCatalog.template(id: "xcode"))
    XCTAssertTrue(templates.allSatisfy { !$0.patterns.isEmpty })
  }
}
