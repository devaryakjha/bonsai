import Foundation
import XCTest
@testable import Bonsai

final class GitClientIntegrationTests: XCTestCase {
  private let client = GitClient()

  func testRepositorySwitchClearsStaleSelectionState() async throws {
    let first = try await makeRepository()
    try write("one\n", to: first.appending(path: "first.txt"))
    try await commitAll(in: first, message: "First repo")

    let second = try await makeRepository()
    try write("two\n", to: second.appending(path: "second.txt"))
    try await commitAll(in: second, message: "Second repo")

    let store = await RepositoryStore()
    await store.openRepository(at: first)
    let firstCommit = await store.selectedCommit
    XCTAssertEqual(firstCommit?.subject, "First repo")

    await store.openRepository(at: second)

    let selectedRepository = await store.selectedRepository
    let selectedCommit = await store.selectedCommit
    let errorMessage = await store.errorMessage
    XCTAssertEqual(selectedRepository?.path, second.path(percentEncoded: false))
    XCTAssertEqual(selectedCommit?.subject, "Second repo")
    XCTAssertNil(errorMessage)
  }

  func testModeSwitchSelectsMatchingDiffSurface() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "tracked.txt")
    try write("before\n", to: file)
    try await commitAll(in: repo, message: "Initial")
    try write("after\n", to: file)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.mainMode = .changes
    }
    try await Task.sleep(nanoseconds: 200_000_000)

    let selectedStatusEntry = await store.selectedStatusEntry
    let selectedChangedFile = await store.selectedChangedFile
    let diffText = await store.diffText
    XCTAssertEqual(selectedStatusEntry?.path, "tracked.txt")
    XCTAssertNil(selectedChangedFile)
    XCTAssertTrue(diffText.contains("+after"))
    XCTAssertFalse(diffText.contains("Initial"))
  }

  func testWorkingTreeHunkCommitAndReadOnlyActions() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "file.txt")
    try write((1...24).map { "line \($0)" }.joined(separator: "\n") + "\n", to: file)
    try await commitAll(in: repo, message: "Initial file")

    try write((1...24).map { index in
      if index == 2 { return "line two changed" }
      if index == 20 { return "line twenty changed" }
      return "line \(index)"
    }.joined(separator: "\n") + "\n", to: file)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    guard let entry = try await client.status(in: repository).first else {
      return XCTFail("Expected a modified file")
    }

    let diff = try await client.diffForWorkingTreeFile(entry, staged: false, algorithm: .histogram, in: repository)
    let hunks = GitParsers.parseDiffHunks(diff)
    XCTAssertEqual(hunks.count, 2)

    _ = try await client.stageHunk(hunks[0], in: repository)
    var status = try await client.status(in: repository)
    XCTAssertTrue(status.contains { $0.isStaged })

    let stagedEntry = try XCTUnwrap(status.first { $0.isStaged })
    let stagedDiff = try await client.diffForWorkingTreeFile(stagedEntry, staged: true, algorithm: .histogram, in: repository)
    let stagedHunk = try XCTUnwrap(GitParsers.parseDiffHunks(stagedDiff).first)
    _ = try await client.unstageHunk(stagedHunk, in: repository)
    status = try await client.status(in: repository)
    XCTAssertFalse(status.contains { $0.isStaged })

    _ = try await client.stage(entry, in: repository)
    _ = try await client.commit(message: "Update file", amend: false, sign: false, in: repository)

    let commits = try await client.commits(in: repository)
    let commit = try XCTUnwrap(commits.first)
    let changedFiles = try await client.changedFiles(in: repository, commit: commit)
    let changedFile = try XCTUnwrap(changedFiles.first)
    XCTAssertEqual(changedFile.path, "file.txt")
    let commitDiff = try await client.diffForCommitFile(changedFile, commit: commit, algorithm: .histogram, in: repository)
    let reflog = try await client.reflog(in: repository)
    let blame = try await client.blame(path: "file.txt", in: repository)
    let fileHistory = try await client.fileHistory(path: "file.txt", in: repository)
    XCTAssertTrue(commitDiff.contains("line twenty changed"))
    XCTAssertTrue(reflog.contains("Update file"))
    XCTAssertTrue(blame.contains("line twenty changed"))
    XCTAssertTrue(fileHistory.contains("Update file"))
  }

  func testLineChangeStagingLeavesOtherChangesUnstaged() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "file.txt")
    try write((1...20).map { "line \($0)" }.joined(separator: "\n") + "\n", to: file)
    try await commitAll(in: repo, message: "Initial file")

    try write((1...20).map { index in
      if index == 2 { return "line two changed" }
      if index == 18 { return "line eighteen changed" }
      return "line \(index)"
    }.joined(separator: "\n") + "\n", to: file)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let initialStatus = try await client.status(in: repository)
    let entry = try XCTUnwrap(initialStatus.first)
    let diff = try await client.diffForWorkingTreeFile(entry, staged: false, algorithm: .histogram, in: repository)
    let firstHunk = try XCTUnwrap(GitParsers.parseDiffHunks(diff).first)
    let firstLineChange = try XCTUnwrap(GitParsers.parseDiffLineChanges(firstHunk).first)

    _ = try await client.stageLineChange(firstLineChange, in: repository)

    let status = try await client.status(in: repository)
    let stagedEntry = try XCTUnwrap(status.first { $0.isStaged })
    let unstagedEntry = try XCTUnwrap(status.first { !$0.isStaged })
    let stagedDiff = try await client.diffForWorkingTreeFile(stagedEntry, staged: true, algorithm: .histogram, in: repository)
    let unstagedDiff = try await client.diffForWorkingTreeFile(unstagedEntry, staged: false, algorithm: .histogram, in: repository)

    XCTAssertTrue(stagedDiff.contains("line two changed"))
    XCTAssertFalse(stagedDiff.contains("line eighteen changed"))
    XCTAssertTrue(unstagedDiff.contains("line eighteen changed"))

    _ = try await client.unstageLineChange(firstLineChange, in: repository)
    let finalStatus = try await client.status(in: repository)
    XCTAssertFalse(finalStatus.contains { $0.isStaged })
    let finalEntry = try XCTUnwrap(finalStatus.first)
    let finalDiff = try await client.diffForWorkingTreeFile(finalEntry, staged: false, algorithm: .histogram, in: repository)
    XCTAssertTrue(finalDiff.contains("line two changed"))
    XCTAssertTrue(finalDiff.contains("line eighteen changed"))
  }

  func testImageDiffSnapshotsReadWorkingTreeIndexAndCommitBlobs() async throws {
    let repo = try await makeRepository()
    let image = repo.appending(path: "image.png")
    let firstImage = try XCTUnwrap(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="))
    let secondImage = try XCTUnwrap(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR42mNk+M8AAwUBAZsJTYQAAAAASUVORK5CYII="))

    try write(firstImage, to: image)
    try await commitAll(in: repo, message: "Initial image")

    try write(secondImage, to: image)
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    var status = try await client.status(in: repository)
    let unstagedEntry = try XCTUnwrap(status.first { $0.path == "image.png" && !$0.isStaged })

    var snapshot = await client.imageDiffForWorkingTreeFile(unstagedEntry, in: repository)
    XCTAssertEqual(snapshot.oldData, firstImage)
    XCTAssertEqual(snapshot.newData, secondImage)

    _ = try await client.stage(unstagedEntry, in: repository)
    status = try await client.status(in: repository)
    let stagedEntry = try XCTUnwrap(status.first { $0.path == "image.png" && $0.isStaged })

    snapshot = await client.imageDiffForWorkingTreeFile(stagedEntry, in: repository)
    XCTAssertEqual(snapshot.oldData, firstImage)
    XCTAssertEqual(snapshot.newData, secondImage)

    _ = try await client.commit(message: "Update image", amend: false, sign: false, in: repository)
    let commits = try await client.commits(in: repository)
    let commit = try XCTUnwrap(commits.first)
    let changedFiles = try await client.changedFiles(in: repository, commit: commit)
    let changedFile = try XCTUnwrap(changedFiles.first { $0.path == "image.png" })

    snapshot = await client.imageDiffForCommitFile(changedFile, commit: commit, in: repository)
    XCTAssertEqual(snapshot.oldData, firstImage)
    XCTAssertEqual(snapshot.newData, secondImage)
  }

  func testDiscardTrackedAndUntrackedChanges() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "file.txt")
    let scratch = repo.appending(path: "scratch.txt")
    try write("original\n", to: file)
    try await commitAll(in: repo, message: "Initial file")

    try write("changed\n", to: file)
    try write("scratch\n", to: scratch)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    var status = try await client.status(in: repository)
    let tracked = try XCTUnwrap(status.first { $0.path == "file.txt" })
    let untracked = try XCTUnwrap(status.first { $0.path == "scratch.txt" })

    _ = try await client.discard(tracked, in: repository)
    XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "original\n")

    _ = try await client.discard(untracked, in: repository)
    XCTAssertFalse(FileManager.default.fileExists(atPath: scratch.path(percentEncoded: false)))

    status = try await client.status(in: repository)
    XCTAssertTrue(status.isEmpty)
  }

  func testRefsStashesRemotesAndRepositoryActions() async throws {
    let remote = try await makeBareRepository()
    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))

    try write("seed\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: repo)
    _ = try await client.git(["push", "-u", "origin", "main"], in: repo)

    _ = try await client.runAction(.fetch, in: repository)
    _ = try await client.runAction(.pull, in: repository)
    _ = try await client.runAction(.push, in: repository)
    let remotes = try await client.remotes(in: repository)
    XCTAssertEqual(remotes.first?.name, "origin")

    _ = try await client.createBranch(named: "feature/test", startPoint: nil, in: repository)
    var refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "feature/test" })
    _ = try await client.checkout("feature/test", in: repository)
    _ = try await client.checkout("main", in: repository)
    _ = try await client.deleteBranch("feature/test", force: false, in: repository)

    _ = try await client.createTag(named: "v0.1.0", target: nil, in: repository)
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "v0.1.0" })
    _ = try await client.deleteTag("v0.1.0", in: repository)

    try write("dirty\n", to: repo.appending(path: "README.md"))
    _ = try await client.stashPush(message: "save dirty readme", in: repository)
    var stashes = try await client.stashes(in: repository)
    let stash = try XCTUnwrap(stashes.first)
    let stashFiles = try await client.changedFiles(in: repository, stash: stash)
    let stashFile = try XCTUnwrap(stashFiles.first)
    let stashDiff = try await client.diffForStashFile(stashFile, stash: stash, algorithm: .histogram, in: repository)
    XCTAssertEqual(stashFile.path, "README.md")
    XCTAssertTrue(stashDiff.contains("+dirty"))
    _ = try await client.stashApply(stash, pop: false, in: repository)
    _ = try await client.git(["checkout", "--", "README.md"], in: repo)
    _ = try await client.stashDrop(stash, in: repository)
    stashes = try await client.stashes(in: repository)
    XCTAssertTrue(stashes.isEmpty)
  }

  func testSubmoduleListingAndSingleUpdate() async throws {
    let child = try await makeRepository()
    try write("child\n", to: child.appending(path: "README.md"))
    try await commitAll(in: child, message: "Child")

    let repo = try await makeRepository()
    _ = try await client.git([
      "-c",
      "protocol.file.allow=always",
      "submodule",
      "add",
      child.path(percentEncoded: false),
      "Vendor/Child"
    ], in: repo)
    try await commitAll(in: repo, message: "Add submodule")

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let submodules = try await client.submodules(in: repository)
    let submodule = try XCTUnwrap(submodules.first)
    XCTAssertEqual(submodule.path, "Vendor/Child")
    XCTAssertEqual(submodule.statusTitle, "Ready")

    _ = try await client.updateSubmodule(submodule, in: repository)
    let refreshed = try await client.submodules(in: repository)
    XCTAssertEqual(refreshed.first?.path, "Vendor/Child")
  }

  func testCommitTreeBrowsingReadsNestedBlobText() async throws {
    let repo = try await makeRepository()
    try write("root\n", to: repo.appending(path: "README.md"))
    try write("nested\n", to: repo.appending(path: "Sources/App.swift"))
    try await commitAll(in: repo, message: "Tree")

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let commits = try await client.commits(in: repository)
    let commit = try XCTUnwrap(commits.first)
    let rootEntries = try await client.treeEntries(in: repository, commit: commit)
    let sources = try XCTUnwrap(rootEntries.first { $0.name == "Sources" })
    XCTAssertTrue(sources.isDirectory)

    let sourceEntries = try await client.treeEntries(in: repository, commit: commit, path: sources.path)
    let appFile = try XCTUnwrap(sourceEntries.first { $0.name == "App.swift" })
    let text = try await client.blobText(path: appFile.path, commit: commit, in: repository)

    XCTAssertEqual(appFile.path, "Sources/App.swift")
    XCTAssertEqual(text, "nested\n")
  }

  func testCreateListAndRemoveWorktree() async throws {
    let repo = try await makeRepository()
    try write("root\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Initial")

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let worktreeURL = temporaryDirectory()
    let worktreePath = canonicalPath(worktreeURL)
    _ = try await client.createWorktree(at: worktreeURL.path(percentEncoded: false), startPoint: "HEAD", in: repository)

    var worktrees = try await client.worktrees(in: repository)
    let created = try XCTUnwrap(worktrees.first { canonicalPath($0.path) == worktreePath })
    XCTAssertTrue(created.isDetached)

    _ = try await client.removeWorktree(created, in: repository)
    worktrees = try await client.worktrees(in: repository)
    XCTAssertFalse(worktrees.contains { canonicalPath($0.path) == worktreePath })
  }

  func testCloneInteractiveRebaseAndConflictResolution() async throws {
    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    try write("base\n", to: source.appending(path: "story.txt"))
    try await commitAll(in: source, message: "Base")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)

    let clone = temporaryDirectory().appending(path: "clone", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: clone.deletingLastPathComponent(), withIntermediateDirectories: true)
    _ = try await client.cloneRepository(from: remote.path(percentEncoded: false), to: clone)
    let repository = GitRepository(path: clone.path(percentEncoded: false))
    try await client.validateRepository(at: clone)

    try write("base\nsecond\n", to: clone.appending(path: "story.txt"))
    try await commitAll(in: clone, message: "Second")
    try write("base\nsecond\nthird\n", to: clone.appending(path: "story.txt"))
    try await commitAll(in: clone, message: "Third")

    let plan = try await client.interactiveRebasePlan(in: repository)
    XCTAssertGreaterThanOrEqual(plan.items.count, 2)
    _ = try await client.startInteractiveRebase(plan, in: repository)

    _ = try await client.checkout("main", in: repository)
    _ = try await client.createBranch(named: "side", startPoint: nil, in: repository)
    _ = try await client.checkout("side", in: repository)
    try write("side\n", to: clone.appending(path: "story.txt"))
    try await commitAll(in: clone, message: "Side change")
    _ = try await client.checkout("main", in: repository)
    try write("main\n", to: clone.appending(path: "story.txt"))
    try await commitAll(in: clone, message: "Main change")

    do {
      _ = try await client.runRaw(["merge", "side"], in: repository)
      XCTFail("Expected merge conflict")
    } catch {
      let conflicted = try await client.status(in: repository).first { $0.isConflicted }
      let entry = try XCTUnwrap(conflicted)
      _ = try await client.resolveConflict(entry, choice: .ours, in: repository)
      let status = try await client.status(in: repository)
      XCTAssertFalse(status.contains { $0.isConflicted })
    }
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

  private func commitAll(in repository: URL, message: String) async throws {
    _ = try await client.git(["add", "."], in: repository)
    _ = try await client.git(["commit", "-m", message], in: repository)
  }

  private func write(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try text.write(to: url, atomically: true, encoding: .utf8)
  }

  private func write(_ data: Data, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
  }

  private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "bonsai-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
  }

  private func canonicalPath(_ url: URL) -> String {
    url.resolvingSymlinksInPath().path(percentEncoded: false)
  }

  private func canonicalPath(_ path: String) -> String {
    URL(filePath: path).resolvingSymlinksInPath().path(percentEncoded: false)
  }
}
