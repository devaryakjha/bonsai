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

  func testStoreRenamesRemoteAndUpdatesURL() async throws {
    let repo = try await makeRepository()
    let firstRemote = try await makeBareRepository()
    let secondRemote = try await makeBareRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    _ = try await client.addRemote(name: "backup", url: firstRemote.path(percentEncoded: false), in: repository)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let remotes = await store.snapshot.remotes
    let backup = try XCTUnwrap(remotes.first { $0.name == "backup" })
    await MainActor.run {
      store.presentEditRemote(backup)
    }

    await store.saveRemote(name: "upstream", url: secondRemote.path(percentEncoded: false))

    let updatedRemotes = try await client.remotes(in: repository)
    let commandResult = await store.commandResult
    XCTAssertFalse(updatedRemotes.contains { $0.name == "backup" })
    XCTAssertEqual(updatedRemotes.first { $0.name == "upstream" }?.fetchURL, secondRemote.path(percentEncoded: false))
    XCTAssertEqual(commandResult?.title, "Edit remote")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testFetchSingleRemoteUpdatesTrackingRefs() async throws {
    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    try write("remote\n", to: source.appending(path: "README.md"))
    try await commitAll(in: source, message: "Remote seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)

    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    _ = try await client.addRemote(name: "origin", url: remote.path(percentEncoded: false), in: repository)
    let remotes = try await client.remotes(in: repository)
    let origin = try XCTUnwrap(remotes.first { $0.name == "origin" })

    _ = try await client.fetchRemote(origin, in: repository)

    let refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "origin/main" && $0.kind == .remoteBranch })
  }

  func testStorePrunesStaleRemoteTrackingBranch() async throws {
    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    try write("seed\n", to: source.appending(path: "README.md"))
    try await commitAll(in: source, message: "Remote seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)
    _ = try await client.git(["checkout", "-b", "stale"], in: source)
    try write("stale\n", to: source.appending(path: "stale.txt"))
    try await commitAll(in: source, message: "Stale branch")
    _ = try await client.git(["push", "-u", "origin", "stale"], in: source)

    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    _ = try await client.addRemote(name: "origin", url: remote.path(percentEncoded: false), in: repository)
    let remotes = try await client.remotes(in: repository)
    let origin = try XCTUnwrap(remotes.first { $0.name == "origin" })
    _ = try await client.fetchRemote(origin, in: repository)
    let refsBeforePrune = try await client.refs(in: repository)
    XCTAssertTrue(refsBeforePrune.contains { $0.shortName == "origin/stale" && $0.kind == .remoteBranch })

    _ = try await client.git(["checkout", "main"], in: source)
    _ = try await client.git(["push", "origin", "--delete", "stale"], in: source)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await store.pruneRemote(origin)

    let refs = try await client.refs(in: repository)
    let commandResult = await store.commandResult
    XCTAssertFalse(refs.contains { $0.shortName == "origin/stale" && $0.kind == .remoteBranch })
    XCTAssertEqual(commandResult?.title, "Prune origin")
    XCTAssertEqual(commandResult?.isError, false)
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
    _ = try await client.git(["symbolic-ref", "HEAD", "refs/heads/main"], in: url)
    return url
  }

  private func commitAll(in repository: URL, message: String) async throws {
    _ = try await client.git(["add", "."], in: repository)
    _ = try await client.git(["commit", "-m", message], in: repository)
  }

  private func write(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try text.write(to: url, atomically: true, encoding: .utf8)
  }

  private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "bonsai-remote-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
  }
}
