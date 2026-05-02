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
    refs/heads/main\u{1f}abc123\u{1f}origin/main\u{1f}*
    refs/remotes/origin/main\u{1f}abc123\u{1f}\u{1f}
    refs/tags/v0.1.0\u{1f}def456\u{1f}\u{1f}
    """)

    XCTAssertEqual(refs.count, 3)
    XCTAssertEqual(refs[0].kind, .localBranch)
    XCTAssertTrue(refs[0].isHead)
    XCTAssertEqual(refs[0].upstream, "origin/main")
    XCTAssertEqual(refs[1].kind, .remoteBranch)
    XCTAssertEqual(refs[2].kind, .tag)
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
