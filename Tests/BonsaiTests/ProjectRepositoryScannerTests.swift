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

  @MainActor
  func testCloneDestinationIsDerivedFromParentAndRemoteURL() {
    let parent = URL(filePath: "/Users/example/projects", directoryHint: .isDirectory)

    XCTAssertEqual(
      RepositoryStore.cloneDestination(parentDirectory: parent, remoteURL: "https://github.com/example/bonsai.git").path(percentEncoded: false),
      "/Users/example/projects/bonsai"
    )
    XCTAssertEqual(
      RepositoryStore.cloneDestination(parentDirectory: parent, remoteURL: "git@github.com:example/bonsai.git").path(percentEncoded: false),
      "/Users/example/projects/bonsai"
    )
    XCTAssertEqual(
      RepositoryStore.cloneDestination(parentDirectory: parent, remoteURL: " ").path(percentEncoded: false),
      "/Users/example/projects/Repository"
    )
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
    XCTAssertEqual(groups.first { $0.name == "Projects" }?.path, root.path(percentEncoded: false))
    XCTAssertEqual(groups.first { $0.name == "mobile" }?.path, root.appending(path: "mobile").path(percentEncoded: false))
    XCTAssertEqual(groups.first { $0.name == "services" }?.path, root.appending(path: "services").path(percentEncoded: false))
    XCTAssertEqual(groups.first { $0.name == "Projects" }?.repositories.map(\.name), ["bonsai"])
    XCTAssertEqual(groups.first { $0.name == "mobile" }?.repositories.map(\.name), ["chibi"])
    XCTAssertEqual(groups.first { $0.name == "services" }?.repositories.map(\.name), ["api"])
  }

  func testConfiguredSourceDirectoriesTrimExpandAndDedupePaths() {
    let directories = ProjectRepositoryScanner.configuredSourceDirectories(rawValue: """
      ~/projects

      ~/projects
      /tmp/repos
    """)

    XCTAssertEqual(directories.map { $0.path(percentEncoded: false) }, [
      NSHomeDirectory() + "/projects",
      "/tmp/repos"
    ])
  }

  func testConfiguredSourceDirectoriesFallsBackToProjectsWhenEmpty() {
    let directories = ProjectRepositoryScanner.configuredSourceDirectories(rawValue: " \n ")

    XCTAssertEqual(directories.map { $0.path(percentEncoded: false) }, [
      ProjectRepositoryScanner.defaultSourceDirectoryText
    ])
  }

  func testWorkspaceGroupsCanScanMultipleSourceDirectories() throws {
    let firstRoot = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-source-a-\(UUID().uuidString)", directoryHint: .isDirectory)
    let secondRoot = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-source-b-\(UUID().uuidString)", directoryHint: .isDirectory)
    let firstDirect = firstRoot.appending(path: "bonsai", directoryHint: .isDirectory)
    let firstNested = firstRoot.appending(path: "tools/loadwright", directoryHint: .isDirectory)
    let secondDirect = secondRoot.appending(path: "kite", directoryHint: .isDirectory)

    try FileManager.default.createDirectory(at: firstDirect.appending(path: ".git"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: firstNested.appending(path: ".git"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: secondDirect.appending(path: ".git"), withIntermediateDirectories: true)
    defer {
      try? FileManager.default.removeItem(at: firstRoot)
      try? FileManager.default.removeItem(at: secondRoot)
    }

    let groups = ProjectRepositoryScanner.workspaceGroups(under: [firstRoot, secondRoot], maxDepth: 2)

    XCTAssertEqual(groups.map(\.name), [
      firstRoot.lastPathComponent,
      "\(firstRoot.lastPathComponent) / tools",
      secondRoot.lastPathComponent
    ])
    XCTAssertEqual(groups.first { $0.name == firstRoot.lastPathComponent }?.repositories.map(\.name), ["bonsai"])
    XCTAssertEqual(groups.first { $0.name.hasSuffix("tools") }?.repositories.map(\.name), ["loadwright"])
    XCTAssertEqual(groups.first { $0.name == secondRoot.lastPathComponent }?.repositories.map(\.name), ["kite"])
  }
}
