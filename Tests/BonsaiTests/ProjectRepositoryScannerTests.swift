import Foundation
import XCTest
@testable import Bonsai

final class ProjectRepositoryScannerTests: XCTestCase {
  @MainActor
  func testRepositoryNameIsDerivedFromCommonRemoteURLFormats() {
    XCTAssertEqual(RepositoryStore.repositoryName(fromRemoteURL: "https://github.com/example/bonsai.git"), "bonsai")
    XCTAssertEqual(RepositoryStore.repositoryName(fromRemoteURL: "git@github.com:example/bonsai.git"), "bonsai")
    XCTAssertEqual(RepositoryStore.repositoryName(fromRemoteURL: "ssh://git@example.com/example/bonsai"), "bonsai")
  }

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

  func testWorkspaceGroupsUseTopLevelProjectFolders() throws {
    let root = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-groups-\(UUID().uuidString)", directoryHint: .isDirectory)
    let direct = root.appending(path: "bonsai", directoryHint: .isDirectory)
    let mobile = root.appending(path: "mobile/chibi", directoryHint: .isDirectory)
    let backend = root.appending(path: "services/api", directoryHint: .isDirectory)

    try FileManager.default.createDirectory(at: direct.appending(path: ".git"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: mobile.appending(path: ".git"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: backend.appending(path: ".git"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let groups = ProjectRepositoryScanner.workspaceGroups(under: root, maxDepth: 2)

    XCTAssertEqual(groups.map(\.name), ["Projects", "mobile", "services"])
    XCTAssertEqual(groups.first { $0.name == "Projects" }?.repositories.map(\.name), ["bonsai"])
    XCTAssertEqual(groups.first { $0.name == "mobile" }?.repositories.map(\.name), ["chibi"])
    XCTAssertEqual(groups.first { $0.name == "services" }?.repositories.map(\.name), ["api"])
  }
}
