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
    XCTAssertEqual(refs[0].pullTitle, "Pull 1")
    XCTAssertEqual(refs[0].pushTitle, "Push 2")
    XCTAssertEqual(refs[1].pullTitle, "Pull")
    XCTAssertEqual(refs[1].pushTitle, "Push")
    XCTAssertTrue(refs[1].upstreamGone)
    XCTAssertEqual(refs[1].trackingSummary, "gone")
    XCTAssertEqual(refs[2].kind, .remoteBranch)
    XCTAssertEqual(refs[3].kind, .tag)
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
    XCTAssertEqual(entries[0].name, "README.md")
    XCTAssertEqual(entries[0].path, "Root/README.md")
    XCTAssertTrue(entries[1].isDirectory)
    XCTAssertEqual(entries[1].path, "Root/Sources App")
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
    XCTAssertEqual(copied.statusCode, "C")
    XCTAssertEqual(copied.statusTitle, "Copied (C75)")
    XCTAssertEqual(modified.statusCode, "M")
    XCTAssertEqual(modified.statusTitle, "Modified")
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

  func testParseLFSFilesExtractsOidAndPath() {
    let files = GitParsers.parseLFSFiles("""
    2f9c2a4d3b * Assets/image.png
    aaaaa11111 - Fixtures/archive.zip
    """)

    XCTAssertEqual(files.count, 2)
    XCTAssertEqual(files[0].oid, "2f9c2a4d3b")
    XCTAssertEqual(files[0].path, "Assets/image.png")
    XCTAssertEqual(files[1].path, "Fixtures/archive.zip")
  }
}
