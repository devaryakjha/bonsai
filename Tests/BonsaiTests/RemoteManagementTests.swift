import Foundation
import XCTest
@testable import Bonsai

final class RemoteManagementTests: XCTestCase {
  private let client = GitClient()

  func testAddUpdateAndRemoveRemote() async throws {
    let repo = try await makeRepository()
    let firstRemote = try await makeBareRepository()
    let secondRemote = try await makeBareRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))

    _ = try await client.addRemote(name: "backup", url: firstRemote.path(percentEncoded: false), in: repository)
    var remotes = try await client.remotes(in: repository)
    XCTAssertEqual(remotes.first { $0.name == "backup" }?.fetchURL, firstRemote.path(percentEncoded: false))

    _ = try await client.setRemoteURL(name: "backup", url: secondRemote.path(percentEncoded: false), in: repository)
    remotes = try await client.remotes(in: repository)
    XCTAssertEqual(remotes.first { $0.name == "backup" }?.fetchURL, secondRemote.path(percentEncoded: false))

    _ = try await client.removeRemote(name: "backup", in: repository)
    remotes = try await client.remotes(in: repository)
    XCTAssertFalse(remotes.contains { $0.name == "backup" })
  }

  private func makeRepository() async throws -> URL {
    let url = temporaryDirectory()
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    _ = try await client.initializeRepository(at: url)
    _ = try await client.git(["branch", "-M", "main"], in: url)
    _ = try await client.git(["config", "user.name", "Bonsai Tests"], in: url)
    _ = try await client.git(["config", "user.email", "bonsai@example.test"], in: url)
    return url
  }

  private func makeBareRepository() async throws -> URL {
    let url = temporaryDirectory()
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    _ = try await client.git(["init", "--bare"], in: url)
    return url
  }

  private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "bonsai-remote-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
  }
}
