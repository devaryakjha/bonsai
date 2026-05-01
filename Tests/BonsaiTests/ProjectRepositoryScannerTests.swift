import Foundation
import XCTest
@testable import Bonsai

final class ProjectRepositoryScannerTests: XCTestCase {
  func testScannerFindsGitRepositoriesWithoutDescendingIntoRepositoryChildren() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-scanner-\(UUID().uuidString)", directoryHint: .isDirectory)
    let repo = root.appending(path: "repo", directoryHint: .isDirectory)
    let nested = repo.appending(path: "nested", directoryHint: .isDirectory)
    let other = root.appending(path: "group/other", directoryHint: .isDirectory)

    try FileManager.default.createDirectory(at: repo.appending(path: ".git"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: nested.appending(path: ".git"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: other.appending(path: ".git"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let repositories = ProjectRepositoryScanner.scanRepositories(under: root, maxDepth: 2)
    let names = repositories.map(\.name)

    XCTAssertEqual(Set(names), Set(["repo", "other"]))
  }
}
