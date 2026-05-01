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
    """)

    XCTAssertEqual(entries.count, 5)
    XCTAssertEqual(entries[0].path, "Sources/App.swift")
    XCTAssertFalse(entries[0].isStaged)
    XCTAssertEqual(entries[1].kind, .added)
    XCTAssertTrue(entries[1].isStaged)
    XCTAssertTrue(entries[2].isUntracked)
    XCTAssertTrue(entries[3].isConflicted)
    XCTAssertEqual(entries[4].originalPath, "Old.swift")
    XCTAssertEqual(entries[4].path, "New.swift")
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
}
