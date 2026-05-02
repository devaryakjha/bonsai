import XCTest
@testable import Bonsai

final class InspectionFilterTests: XCTestCase {
  func testFileHistoryFilterMatchesCommitAndChangeFields() {
    let entries = [
      GitFileHistoryEntry(
        hash: "abcdef123456",
        shortHash: "abcdef1",
        authorName: "Asha",
        authorEmail: "asha@example.com",
        date: nil,
        subject: "Move repository scanner",
        changes: [
          GitChangedFile(status: "R100", path: "Sources/Scanner.swift", oldPath: "Scanner.swift")
        ]
      ),
      GitFileHistoryEntry(
        hash: "999999999999",
        shortHash: "9999999",
        authorName: "Dev",
        authorEmail: "dev@example.com",
        date: nil,
        subject: "Polish toolbar",
        changes: [
          GitChangedFile(status: "M", path: "Sources/Toolbar.swift", oldPath: nil)
        ]
      )
    ]

    XCTAssertEqual(InspectionFilter.fileHistory(entries, matching: "asha scanner").map(\.shortHash), ["abcdef1"])
    XCTAssertEqual(InspectionFilter.fileHistory(entries, matching: "renamed").map(\.shortHash), ["abcdef1"])
    XCTAssertEqual(InspectionFilter.fileHistory(entries, matching: "modified toolbar").map(\.shortHash), ["9999999"])
    XCTAssertEqual(InspectionFilter.fileHistory(entries, matching: "   ").map(\.shortHash), ["abcdef1", "9999999"])
  }

  func testBlameFilterMatchesCommitAuthorLineAndContent() {
    let lines = [
      GitBlameLine(
        id: 1,
        commitHash: "abcdef123456",
        shortHash: "abcdef1",
        author: "Asha",
        authorMail: "asha@example.com",
        authorTime: nil,
        originalLine: 10,
        finalLine: 12,
        content: "let scanner = ProjectRepositoryScanner()"
      ),
      GitBlameLine(
        id: 2,
        commitHash: "999999999999",
        shortHash: "9999999",
        author: "Dev",
        authorMail: nil,
        authorTime: nil,
        originalLine: 20,
        finalLine: 24,
        content: "renderToolbar()"
      )
    ]

    XCTAssertEqual(InspectionFilter.blameLines(lines, matching: "asha scanner").map(\.id), [1])
    XCTAssertEqual(InspectionFilter.blameLines(lines, matching: "24").map(\.id), [2])
    XCTAssertEqual(InspectionFilter.blameLines(lines, matching: "abcdef").map(\.id), [1])
    XCTAssertEqual(InspectionFilter.blameLines(lines, matching: "").map(\.id), [1, 2])
  }
}
