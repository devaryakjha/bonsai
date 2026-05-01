import XCTest
@testable import Bonsai

final class CommitFilterTests: XCTestCase {
  func testFilterMatchesSubjectAuthorHashAndDecoration() {
    let commits = [
      GitCommit(
        hash: "abcdef123456",
        shortHash: "abcdef1",
        authorName: "Ari",
        authorEmail: "ari@example.test",
        date: nil,
        subject: "Add repository manager",
        decorations: ["HEAD -> main"]
      ),
      GitCommit(
        hash: "999999999999",
        shortHash: "9999999",
        authorName: "Mina",
        authorEmail: "mina@example.test",
        date: nil,
        subject: "Fix diff renderer",
        decorations: ["tag: v0.1.0"]
      )
    ]

    XCTAssertEqual(CommitFilter.filter(commits, query: "manager").map(\.shortHash), ["abcdef1"])
    XCTAssertEqual(CommitFilter.filter(commits, query: "mina").map(\.shortHash), ["9999999"])
    XCTAssertEqual(CommitFilter.filter(commits, query: "abc").map(\.shortHash), ["abcdef1"])
    XCTAssertEqual(CommitFilter.filter(commits, query: "v0.1").map(\.shortHash), ["9999999"])
    XCTAssertEqual(CommitFilter.filter(commits, query: "").count, 2)
  }
}
