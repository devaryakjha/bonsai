import AppKit
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

  func testCommitPatchReturnsFullCommitPatch() async throws {
    let repo = try await makeRepository()
    try write("one\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Initial readme")
    try write("one\ntwo\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Expand readme")

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let commits = try await client.commits(in: repository)
    let commit = try XCTUnwrap(commits.first)
    let patch = try await client.commitPatch(commit, algorithm: .histogram, whitespaceMode: .show, in: repository)

    XCTAssertTrue(patch.contains("diff --git a/README.md b/README.md"))
    XCTAssertTrue(patch.contains("+two"))
  }

  func testRepositoryBenchmarkReportsRealRepositoryScaleAndTimings() async throws {
    let repo = try await makeRepository()
    try FileManager.default.createDirectory(at: repo.appending(path: "Sources"), withIntermediateDirectories: true)
    try write("one\n", to: repo.appending(path: "README.md"))
    try write("print(\"bonsai\")\n", to: repo.appending(path: "Sources/App.swift"))
    try await commitAll(in: repo, message: "Initial project")
    try write("one\ntwo\n", to: repo.appending(path: "README.md"))
    try write("notes\n", to: repo.appending(path: "notes.txt"))

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let report = try await client.repositoryBenchmark(in: repository)
    let metrics = Dictionary(uniqueKeysWithValues: report.metrics.map { ($0.title, $0.value) })

    XCTAssertEqual(report.repository.path, repository.path)
    XCTAssertEqual(metrics["Commits"], "1")
    XCTAssertEqual(metrics["Tracked files"], "2")
    XCTAssertEqual(metrics["Working tree changes"], "2")
    XCTAssertEqual(report.timings.count, 5)
    XCTAssertTrue(report.timings.allSatisfy { $0.milliseconds >= 0 })
  }

  func testClearRecentRepositoriesKeepsSelectedRepository() async throws {
    let previousRecents = UserDefaults.standard.data(forKey: "bonsai.recentRepositories")
    defer {
      if let previousRecents {
        UserDefaults.standard.set(previousRecents, forKey: "bonsai.recentRepositories")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.recentRepositories")
      }
    }

    let repo = try await makeRepository()
    let store = await RepositoryStore()
    await store.openRepository(at: repo)

    await store.clearRecentRepositories()

    let selectedRepository = await store.selectedRepository
    let recentRepositories = await store.recentRepositories
    XCTAssertEqual(selectedRepository?.path, repo.path(percentEncoded: false))
    XCTAssertTrue(recentRepositories.isEmpty)
  }

  func testCreateRepositorySetupOpensEmptyRepositoryAndRecordsRecent() async throws {
    let previousRecents = UserDefaults.standard.data(forKey: "bonsai.recentRepositories")
    UserDefaults.standard.removeObject(forKey: "bonsai.recentRepositories")
    defer {
      if let previousRecents {
        UserDefaults.standard.set(previousRecents, forKey: "bonsai.recentRepositories")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.recentRepositories")
      }
    }

    let destination = temporaryDirectory()
    let store = await RepositoryStore()
    await MainActor.run {
      store.repositorySetupMode = .create
      store.repositorySetupDestinationPath = destination.path(percentEncoded: false)
    }

    await store.confirmRepositorySetup()

    try await client.validateRepository(at: destination)
    let selectedRepository = await store.selectedRepository
    let recentRepositories = await store.recentRepositories
    let commandResult = await store.commandResult
    let commits = await store.snapshot.commits
    let errorMessage = await store.errorMessage
    XCTAssertEqual(selectedRepository?.path, destination.path(percentEncoded: false))
    XCTAssertEqual(recentRepositories.first?.path, destination.path(percentEncoded: false))
    XCTAssertEqual(commandResult?.title, "Create repository")
    XCTAssertEqual(commandResult?.isError, false)
    XCTAssertTrue(commits.isEmpty)
    XCTAssertNil(errorMessage)
  }

  func testCloneRepositorySetupOpensCloneAndRecordsRecent() async throws {
    let previousRecents = UserDefaults.standard.data(forKey: "bonsai.recentRepositories")
    UserDefaults.standard.removeObject(forKey: "bonsai.recentRepositories")
    defer {
      if let previousRecents {
        UserDefaults.standard.set(previousRecents, forKey: "bonsai.recentRepositories")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.recentRepositories")
      }
    }

    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    try write("remote\n", to: source.appending(path: "README.md"))
    try await commitAll(in: source, message: "Remote seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)

    let destination = temporaryDirectory()
    let store = await RepositoryStore()
    await MainActor.run {
      store.repositorySetupMode = .clone
      store.repositorySetupRemoteURL = remote.path(percentEncoded: false)
      store.repositorySetupDestinationPath = destination.path(percentEncoded: false)
    }

    await store.confirmRepositorySetup()

    try await client.validateRepository(at: destination)
    let selectedRepository = await store.selectedRepository
    let recentRepositories = await store.recentRepositories
    let commandResult = await store.commandResult
    let commits = await store.snapshot.commits
    let errorMessage = await store.errorMessage
    XCTAssertEqual(selectedRepository?.path, destination.path(percentEncoded: false))
    XCTAssertEqual(recentRepositories.first?.path, destination.path(percentEncoded: false))
    XCTAssertEqual(commandResult?.title, "Clone repository")
    XCTAssertEqual(commandResult?.isError, false)
    XCTAssertEqual(commits.first?.subject, "Remote seed")
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

  func testStoreMutationHonorsAutoRefreshPreference() async throws {
    UserDefaults.standard.set(false, forKey: "bonsai.autoRefresh")
    defer { UserDefaults.standard.removeObject(forKey: "bonsai.autoRefresh") }

    let repo = try await makeRepository()
    let file = repo.appending(path: "tracked.txt")
    try write("before\n", to: file)
    try await commitAll(in: repo, message: "Initial")
    try write("after\n", to: file)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let unstagedBeforeStage = await store.unstagedChanges
    let entry = try XCTUnwrap(unstagedBeforeStage.first)

    await store.stage(entry)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let gitStatus = try await client.status(in: repository)
    let staleStagedChanges = await store.stagedChanges
    let staleUnstagedChanges = await store.unstagedChanges
    XCTAssertTrue(gitStatus.contains { $0.path == "tracked.txt" && $0.isStaged })
    XCTAssertTrue(staleStagedChanges.isEmpty)
    XCTAssertEqual(staleUnstagedChanges.first?.path, "tracked.txt")
  }

  func testStoreTogglesRepositorySigningConfigAndRefreshesStatus() async throws {
    let hadAutoRefreshPreference = UserDefaults.standard.object(forKey: "bonsai.autoRefresh") != nil
    let previousAutoRefreshPreference = UserDefaults.standard.bool(forKey: "bonsai.autoRefresh")
    UserDefaults.standard.set(true, forKey: "bonsai.autoRefresh")
    defer {
      if hadAutoRefreshPreference {
        UserDefaults.standard.set(previousAutoRefreshPreference, forKey: "bonsai.autoRefresh")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.autoRefresh")
      }
    }

    let repo = try await makeRepository()
    try write("initial\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Initial")
    let store = await RepositoryStore()
    await store.openRepository(at: repo)

    await MainActor.run {
      store.signCommit = true
    }
    await store.setCommitSigning(true)

    let enabledConfig = try await client.git(["config", "--get", "commit.gpgsign"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let enabledStatus = await store.snapshot.integrations.gpgSigningEnabled
    let enabledResult = await store.commandResult
    let perCommitSigningAfterEnable = await store.signCommit
    XCTAssertEqual(enabledConfig, "true")
    XCTAssertTrue(enabledStatus)
    XCTAssertEqual(enabledResult?.title, "Enable GPG signing")
    XCTAssertEqual(enabledResult?.isError, false)
    XCTAssertTrue(perCommitSigningAfterEnable)

    await store.setCommitSigning(false)

    let disabledConfig = try await client.git(["config", "--get", "commit.gpgsign"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let disabledStatus = await store.snapshot.integrations.gpgSigningEnabled
    let disabledResult = await store.commandResult
    let perCommitSigningAfterDisable = await store.signCommit
    XCTAssertEqual(disabledConfig, "false")
    XCTAssertFalse(disabledStatus)
    XCTAssertEqual(disabledResult?.title, "Disable GPG signing")
    XCTAssertEqual(disabledResult?.isError, false)
    XCTAssertTrue(perCommitSigningAfterDisable)
  }

  @MainActor
  func testCommitOptionsSummaryReflectsRepositorySigningStatus() {
    let store = RepositoryStore()

    XCTAssertEqual(store.commitOptionsSummary, "")

    store.snapshot.integrations.gpgSigningEnabled = true
    XCTAssertEqual(store.commitOptionsSummary, "Signing on")

    store.amendCommit = true
    XCTAssertEqual(store.commitOptionsSummary, "Amend, signing on")

    store.snapshot.integrations.gpgSigningEnabled = false
    store.signCommit = true
    XCTAssertEqual(store.commitOptionsSummary, "Amend, signing on")
  }

  @MainActor
  func testSelectedFileLFSActionReadinessFollowsAvailabilityAndSelection() {
    let store = RepositoryStore()

    XCTAssertFalse(store.canRunSelectedFileLFSAction)

    store.selectedStatusEntry = GitStatusEntry(
      path: "tracked.bin",
      originalPath: nil,
      indexStatus: " ",
      workTreeStatus: "M",
      kind: .modified
    )
    XCTAssertFalse(store.canRunSelectedFileLFSAction)

    store.snapshot.integrations.lfsAvailable = true
    XCTAssertTrue(store.canRunSelectedFileLFSAction)

    store.selectedStatusEntry = nil
    store.selectedChangedFile = GitChangedFile(status: "M", path: "history.bin", oldPath: nil)
    XCTAssertTrue(store.canRunSelectedFileLFSAction)

    store.selectedChangedFile = nil
    store.selectedTreeEntry = GitTreeEntry(
      mode: "100644",
      kind: .blob,
      object: "abcdef",
      path: "tree.bin",
      name: "tree.bin"
    )
    XCTAssertTrue(store.canRunSelectedFileLFSAction)

    store.selectedTreeEntry = nil
    XCTAssertFalse(store.canRunSelectedFileLFSAction)
  }

  func testSelectedStatusEntryStageCommandsReconcileSelection() async throws {
    let hadAutoRefreshPreference = UserDefaults.standard.object(forKey: "bonsai.autoRefresh") != nil
    let previousAutoRefreshPreference = UserDefaults.standard.bool(forKey: "bonsai.autoRefresh")
    UserDefaults.standard.set(true, forKey: "bonsai.autoRefresh")
    defer {
      if hadAutoRefreshPreference {
        UserDefaults.standard.set(previousAutoRefreshPreference, forKey: "bonsai.autoRefresh")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.autoRefresh")
      }
    }

    let repo = try await makeRepository()
    let file = repo.appending(path: "tracked.txt")
    try write("before\n", to: file)
    try await commitAll(in: repo, message: "Initial")
    try write("after\n", to: file)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let unstagedChanges = await store.unstagedChanges
    let entry = try XCTUnwrap(unstagedChanges.first)

    await store.selectStatusEntry(entry)
    let canStageBefore = await store.canStageSelectedStatusEntry
    let canUnstageBefore = await store.canUnstageSelectedStatusEntry
    XCTAssertTrue(canStageBefore)
    XCTAssertFalse(canUnstageBefore)

    await store.stageSelectedStatusEntry()

    let stagedSelection = await store.selectedStatusEntry
    let canStageAfterStage = await store.canStageSelectedStatusEntry
    let canUnstageAfterStage = await store.canUnstageSelectedStatusEntry
    XCTAssertEqual(stagedSelection?.path, "tracked.txt")
    XCTAssertTrue(stagedSelection?.isStaged == true)
    XCTAssertFalse(canStageAfterStage)
    XCTAssertTrue(canUnstageAfterStage)

    await store.unstageSelectedStatusEntry()

    let unstagedSelection = await store.selectedStatusEntry
    let canStageAfterUnstage = await store.canStageSelectedStatusEntry
    let canUnstageAfterUnstage = await store.canUnstageSelectedStatusEntry
    XCTAssertEqual(unstagedSelection?.path, "tracked.txt")
    XCTAssertTrue(unstagedSelection?.isStaged == false)
    XCTAssertTrue(canStageAfterUnstage)
    XCTAssertFalse(canUnstageAfterUnstage)
  }

  func testBulkStageCommandsMoveAllNonConflictedChanges() async throws {
    let hadAutoRefreshPreference = UserDefaults.standard.object(forKey: "bonsai.autoRefresh") != nil
    let previousAutoRefreshPreference = UserDefaults.standard.bool(forKey: "bonsai.autoRefresh")
    UserDefaults.standard.set(true, forKey: "bonsai.autoRefresh")
    defer {
      if hadAutoRefreshPreference {
        UserDefaults.standard.set(previousAutoRefreshPreference, forKey: "bonsai.autoRefresh")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.autoRefresh")
      }
    }

    let repo = try await makeRepository()
    let modified = repo.appending(path: "modified.txt")
    let deleted = repo.appending(path: "deleted.txt")
    let added = repo.appending(path: "added.txt")
    try write("before\n", to: modified)
    try write("remove me\n", to: deleted)
    try await commitAll(in: repo, message: "Initial")
    try write("after\n", to: modified)
    try FileManager.default.removeItem(at: deleted)
    try write("new\n", to: added)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let unstagedBeforeStage = await store.unstagedChanges
    let canStageBefore = await store.canStageAll
    let canUnstageBefore = await store.canUnstageAll
    XCTAssertEqual(unstagedBeforeStage.count, 3)
    XCTAssertTrue(canStageBefore)
    XCTAssertFalse(canUnstageBefore)

    await store.stageAll()

    let stagedAfterStage = await store.stagedChanges
    let unstagedAfterStage = await store.unstagedChanges
    let canStageAfterStage = await store.canStageAll
    let canUnstageAfterStage = await store.canUnstageAll
    XCTAssertEqual(stagedAfterStage.count, 3)
    XCTAssertTrue(unstagedAfterStage.isEmpty)
    XCTAssertFalse(canStageAfterStage)
    XCTAssertTrue(canUnstageAfterStage)

    await store.unstageAll()

    let stagedAfterUnstage = await store.stagedChanges
    let unstagedAfterUnstage = await store.unstagedChanges
    let canStageAfterUnstage = await store.canStageAll
    let canUnstageAfterUnstage = await store.canUnstageAll
    XCTAssertTrue(stagedAfterUnstage.isEmpty)
    XCTAssertEqual(unstagedAfterUnstage.count, 3)
    XCTAssertTrue(canStageAfterUnstage)
    XCTAssertFalse(canUnstageAfterUnstage)
  }

  func testBulkUnstageWorksBeforeFirstCommit() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "first.txt")
    try write("first\n", to: file)
    let repository = GitRepository(path: repo.path(percentEncoded: false))

    let untracked = try await client.status(in: repository)
    XCTAssertEqual(untracked.count, 1)
    XCTAssertTrue(untracked.first?.isUntracked == true)

    _ = try await client.stageAll(untracked, in: repository)
    let staged = try await client.status(in: repository)
    XCTAssertEqual(staged.count, 1)
    XCTAssertTrue(staged.first?.isStaged == true)

    _ = try await client.unstageAll(staged, in: repository)
    let unstaged = try await client.status(in: repository)
    XCTAssertEqual(unstaged.count, 1)
    XCTAssertTrue(unstaged.first?.isUntracked == true)
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

    let diff = try await client.diffForWorkingTreeFile(entry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)
    let hunks = GitParsers.parseDiffHunks(diff)
    XCTAssertEqual(hunks.count, 2)

    _ = try await client.stageHunk(hunks[0], in: repository)
    var status = try await client.status(in: repository)
    XCTAssertTrue(status.contains { $0.isStaged })

    let stagedEntry = try XCTUnwrap(status.first { $0.isStaged })
    let stagedDiff = try await client.diffForWorkingTreeFile(stagedEntry, staged: true, algorithm: .histogram, whitespaceMode: .show, in: repository)
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
    let commitDiff = try await client.diffForCommitFile(changedFile, commit: commit, algorithm: .histogram, whitespaceMode: .show, in: repository)
    let reflog = try await client.reflogEntries(in: repository)
    let blame = try await client.blameLines(path: "file.txt", in: repository)
    let fileHistory = try await client.fileHistoryEntries(path: "file.txt", in: repository)
    let changedBlameLine = try XCTUnwrap(blame.first { $0.content == "line twenty changed" })
    let resolvedCommit = try await client.commit(revision: changedBlameLine.commitHash, in: repository)
    let lineHistory = try await client.lineHistoryEntries(path: "file.txt", startLine: 20, endLine: 20, in: repository)
    XCTAssertTrue(commitDiff.contains("line twenty changed"))
    XCTAssertTrue(reflog.contains { $0.subject.contains("Update file") })
    XCTAssertFalse(changedBlameLine.shortHash.isEmpty)
    XCTAssertEqual(changedBlameLine.author, "Bonsai Tests")
    XCTAssertEqual(resolvedCommit.subject, "Update file")
    XCTAssertTrue(fileHistory.contains { $0.subject == "Update file" })
    XCTAssertTrue(fileHistory.first?.changes.contains { $0.path == "file.txt" } ?? false)
    XCTAssertTrue(lineHistory.contains { $0.subject == "Update file" })

    let initialCommit = try XCTUnwrap(commits.first { $0.subject == "Initial file" })
    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await store.focusCommit(hash: initialCommit.hash)
    let focusedCommit = await store.selectedCommit
    let mode = await store.mainMode
    XCTAssertEqual(focusedCommit?.hash, initialCommit.hash)
    XCTAssertEqual(mode, .history)
    await store.checkoutSelectedCommit()
    let checkedOutHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    XCTAssertEqual(checkedOutHash, initialCommit.hash)
  }

  func testDiffWhitespaceModeCanHideWhitespaceOnlyChanges() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "file.swift")
    try write("let value = 1\n", to: file)
    try await commitAll(in: repo, message: "Initial file")
    try write("let   value = 1\n", to: file)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let status = try await client.status(in: repository)
    let entry = try XCTUnwrap(status.first)
    let defaultDiff = try await client.diffForWorkingTreeFile(
      entry,
      staged: false,
      algorithm: .histogram,
      whitespaceMode: .show,
      in: repository
    )
    let ignoredDiff = try await client.diffForWorkingTreeFile(
      entry,
      staged: false,
      algorithm: .histogram,
      whitespaceMode: .ignoreAll,
      in: repository
    )

    XCTAssertTrue(defaultDiff.contains("-let value = 1"))
    XCTAssertTrue(defaultDiff.contains("+let   value = 1"))
    XCTAssertTrue(ignoredDiff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  func testStoreTogglesIgnoredFilesVisibility() async throws {
    let previousIgnoredPreference = UserDefaults.standard.object(forKey: "bonsai.showIgnoredFiles")
    UserDefaults.standard.removeObject(forKey: "bonsai.showIgnoredFiles")
    defer {
      if let previousIgnoredPreference {
        UserDefaults.standard.set(previousIgnoredPreference, forKey: "bonsai.showIgnoredFiles")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.showIgnoredFiles")
      }
    }

    let repo = try await makeRepository()
    try write("*.log\n", to: repo.appending(path: ".gitignore"))
    try await commitAll(in: repo, message: "Ignore log output")
    try write("cache\n", to: repo.appending(path: "build/cache.log"))

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let initialStatus = await store.snapshot.status
    let initialIgnoredChanges = await store.ignoredChanges
    XCTAssertFalse(initialStatus.contains { $0.path == "build/cache.log" })
    XCTAssertTrue(initialIgnoredChanges.isEmpty)

    await MainActor.run {
      store.toggleIgnoredFiles()
    }
    await store.refreshAll()
    let ignoredChanges = await store.ignoredChanges
    let ignoredEntry = try XCTUnwrap(ignoredChanges.first)
    XCTAssertEqual(ignoredEntry.path, "build/cache.log")
    XCTAssertEqual(ignoredEntry.kind, .ignored)
    XCTAssertTrue(ignoredEntry.isIgnored)

    await MainActor.run {
      store.selectStatusEntry(ignoredEntry)
    }
    let selectedStatusEntry = await store.selectedStatusEntry
    XCTAssertNil(selectedStatusEntry)

    await MainActor.run {
      store.toggleIgnoredFiles()
    }
    await store.refreshAll()
    let hiddenIgnoredChanges = await store.ignoredChanges
    XCTAssertTrue(hiddenIgnoredChanges.isEmpty)
  }

  func testStoreCleansIgnoredFilesAfterConfirmation() async throws {
    let previousIgnoredPreference = UserDefaults.standard.object(forKey: "bonsai.showIgnoredFiles")
    UserDefaults.standard.removeObject(forKey: "bonsai.showIgnoredFiles")
    defer {
      if let previousIgnoredPreference {
        UserDefaults.standard.set(previousIgnoredPreference, forKey: "bonsai.showIgnoredFiles")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.showIgnoredFiles")
      }
    }

    let repo = try await makeRepository()
    let ignored = repo.appending(path: "build/cache.log")
    let scratch = repo.appending(path: "scratch.txt")
    try write("*.log\n", to: repo.appending(path: ".gitignore"))
    try await commitAll(in: repo, message: "Ignore logs")
    try write("cache\n", to: ignored)
    try write("scratch\n", to: scratch)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let initialCanClean = await store.canCleanIgnoredFiles
    XCTAssertFalse(initialCanClean)

    await MainActor.run {
      store.toggleIgnoredFiles()
    }
    await store.refreshAll()
    let canClean = await store.canCleanIgnoredFiles
    XCTAssertTrue(canClean)

    await MainActor.run {
      store.presentCleanIgnoredFiles()
    }
    let requestValue = await store.cleanIgnoredFilesRequest
    let request = try XCTUnwrap(requestValue)
    XCTAssertEqual(request.fileCount, 1)
    XCTAssertEqual(request.entries.first?.path, "build/cache.log")

    await store.cleanIgnoredFiles()

    XCTAssertFalse(FileManager.default.fileExists(atPath: ignored.path(percentEncoded: false)))
    XCTAssertTrue(FileManager.default.fileExists(atPath: scratch.path(percentEncoded: false)))

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let status = try await client.status(in: repository, includeIgnoredFiles: true)
    XCTAssertFalse(status.contains { $0.path == "build/cache.log" })
    XCTAssertTrue(status.contains { $0.path == "scratch.txt" && $0.isUntracked })
  }

  func testStoreCommitRequiresStagedChangesUnlessAmending() async throws {
    let repo = try await makeRepository()
    try write("initial\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Initial")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.commitMessage = "No staged changes"
    }

    let canCommitWithoutStagedChanges = await store.canCommit
    XCTAssertFalse(canCommitWithoutStagedChanges)
    await store.commit()
    let errorMessage = await store.errorMessage
    let commandResult = await store.commandResult
    XCTAssertEqual(errorMessage, "Stage changes before committing.")
    XCTAssertEqual(commandResult?.title, "Commit")
    XCTAssertEqual(commandResult?.output, "Stage changes before committing.")
    XCTAssertEqual(commandResult?.isError, true)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let commits = try await client.commits(in: repository)
    XCTAssertFalse(commits.contains { $0.subject == "No staged changes" })

    await MainActor.run {
      store.amendCommit = true
    }
    let canAmendWithoutStagedChanges = await store.canCommit
    XCTAssertTrue(canAmendWithoutStagedChanges)
  }

  func testFailedCommitPreservesComposerState() async throws {
    let previousRecentMessages = UserDefaults.standard.data(forKey: "bonsai.recentCommitMessages")
    UserDefaults.standard.removeObject(forKey: "bonsai.recentCommitMessages")
    defer {
      if let previousRecentMessages {
        UserDefaults.standard.set(previousRecentMessages, forKey: "bonsai.recentCommitMessages")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.recentCommitMessages")
      }
    }

    let repo = try await makeRepository()
    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.commitMessage = "Amend missing commit"
      store.amendCommit = true
      store.signCommit = true
    }

    await store.commit()

    let message = await store.commitMessage
    let amendCommit = await store.amendCommit
    let signCommit = await store.signCommit
    let recentCommitMessages = await store.recentCommitMessages
    let commandResult = await store.commandResult
    XCTAssertEqual(message, "Amend missing commit")
    XCTAssertTrue(amendCommit)
    XCTAssertTrue(signCommit)
    XCTAssertFalse(recentCommitMessages.contains("Amend missing commit"))
    XCTAssertEqual(commandResult?.title, "Amend commit")
    XCTAssertEqual(commandResult?.isError, true)
  }

  func testClearRecentCommitMessagesKeepsDraft() async throws {
    let previousRecentMessages = UserDefaults.standard.data(forKey: "bonsai.recentCommitMessages")
    UserDefaults.standard.removeObject(forKey: "bonsai.recentCommitMessages")
    defer {
      if let previousRecentMessages {
        UserDefaults.standard.set(previousRecentMessages, forKey: "bonsai.recentCommitMessages")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.recentCommitMessages")
      }
    }

    let store = await RepositoryStore()
    await MainActor.run {
      store.recentCommitMessages = ["Fix parser", "Update UI"]
      store.commitMessage = "Draft in progress"
    }

    await store.clearRecentCommitMessages()

    let message = await store.commitMessage
    let recentCommitMessages = await store.recentCommitMessages
    XCTAssertEqual(message, "Draft in progress")
    XCTAssertTrue(recentCommitMessages.isEmpty)
  }

  func testStorePullRequiresUsableUpstream() async throws {
    let repo = try await makeRepository()
    try write("initial\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Initial")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let canPullWithoutUpstream = await store.canPull
    XCTAssertFalse(canPullWithoutUpstream)

    await store.runRepositoryAction(.pull)
    let errorMessage = await store.errorMessage
    let commandResult = await store.commandResult
    XCTAssertEqual(errorMessage, "Set an upstream before pulling.")
    XCTAssertEqual(commandResult?.title, "Pull")
    XCTAssertEqual(commandResult?.output, "Set an upstream before pulling.")
    XCTAssertEqual(commandResult?.isError, true)
  }

  func testStorePushRequiresBranchAndRemoteTarget() async throws {
    let repo = try await makeRepository()
    try write("initial\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Initial")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let canPushWithoutRemote = await store.canPush
    XCTAssertFalse(canPushWithoutRemote)

    await store.runRepositoryAction(.push)
    let errorMessage = await store.errorMessage
    let commandResult = await store.commandResult
    XCTAssertEqual(errorMessage, "Add a remote before publishing.")
    XCTAssertEqual(commandResult?.title, "Push")
    XCTAssertEqual(commandResult?.output, "Add a remote before publishing.")
    XCTAssertEqual(commandResult?.isError, true)
  }

  func testStoreCreatesBranchFromStash() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "file.txt")
    try write("initial\n", to: file)
    try await commitAll(in: repo, message: "Initial")
    try write("stashed\n", to: file)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    _ = try await client.stashPush(message: "stash branch", in: repository)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let stashes = await store.snapshot.stashes
    let stash = try XCTUnwrap(stashes.first)
    await MainActor.run {
      store.presentStashBranch(stash)
      store.operationInput = "stash-work"
    }

    await store.confirmOperation()

    let branch = try await client.git(["branch", "--show-current"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    XCTAssertEqual(branch, "stash-work")
    let status = try await client.status(in: repository)
    XCTAssertTrue(status.contains { $0.path == "file.txt" })
    let remainingStashes = try await client.stashes(in: repository)
    XCTAssertTrue(remainingStashes.isEmpty)
  }

  func testStoreCreatesTagAtSelectedHistoryCommit() async throws {
    let repo = try await makeRepository()
    try write("first\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "First")
    let firstHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    try write("second\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Second")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let commits = await store.snapshot.commits
    let firstCommit = try XCTUnwrap(commits.first { $0.hash == firstHash })
    await MainActor.run {
      store.selectCommit(firstCommit)
      store.presentCreateTag()
      store.operationInput = "first-tag"
    }

    await store.confirmOperation()
    let tagHash = try await client.git(["rev-list", "-n", "1", "first-tag"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    XCTAssertEqual(tagHash, firstHash)
  }

  func testStoreCreatesAnnotatedTagAtSelectedHistoryCommit() async throws {
    let repo = try await makeRepository()
    try write("first\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "First")
    let firstHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    try write("second\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Second")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let commits = await store.snapshot.commits
    let firstCommit = try XCTUnwrap(commits.first { $0.hash == firstHash })
    await MainActor.run {
      store.selectCommit(firstCommit)
      store.presentCreateAnnotatedTag()
      store.annotatedTagName = "first-annotated"
      store.annotatedTagMessage = "First annotated release"
    }

    await store.createRequestedAnnotatedTag()

    let tagType = try await client.git(["cat-file", "-t", "refs/tags/first-annotated"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let taggedCommit = try await client.git(["rev-list", "-n", "1", "first-annotated"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let tagContents = try await client.git(["cat-file", "-p", "refs/tags/first-annotated"], in: repo).stdout
    let commandResult = await store.commandResult
    XCTAssertEqual(tagType, "tag")
    XCTAssertEqual(taggedCommit, firstHash)
    XCTAssertTrue(tagContents.contains("First annotated release"))
    XCTAssertEqual(commandResult?.title, "Create annotated tag first-annotated")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreRenamesAnnotatedTagWithoutFlatteningIt() async throws {
    let repo = try await makeRepository()
    try write("initial\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Initial")
    _ = try await client.git(["tag", "-a", "v1.0.0", "-m", "Version 1"], in: repo)
    let originalTagObject = try await client.git(["rev-parse", "refs/tags/v1.0.0"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let tags = await store.tags
    let tag = try XCTUnwrap(tags.first { $0.shortName == "v1.0.0" })
    await MainActor.run {
      store.presentRenameTag(tag)
      store.operationInput = "v1.1.0"
    }

    await store.confirmOperation()

    let oldTagLookup = try? await client.git(["rev-parse", "--verify", "refs/tags/v1.0.0"], in: repo)
    let renamedTagObject = try await client.git(["rev-parse", "refs/tags/v1.1.0"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let renamedTagType = try await client.git(["cat-file", "-t", "refs/tags/v1.1.0"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let refs = try await client.refs(in: GitRepository(path: repo.path(percentEncoded: false)))
    let commandResult = await store.commandResult
    XCTAssertNil(oldTagLookup)
    XCTAssertEqual(renamedTagObject, originalTagObject)
    XCTAssertEqual(renamedTagType, "tag")
    XCTAssertTrue(refs.contains { $0.shortName == "v1.1.0" && $0.kind == .tag })
    XCTAssertFalse(refs.contains { $0.shortName == "v1.0.0" && $0.kind == .tag })
    XCTAssertEqual(commandResult?.title, "Rename tag v1.0.0")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStorePushesTagToRemote() async throws {
    let repo = try await makeRepository()
    let bare = try await makeBareRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    try write("initial\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Initial")
    _ = try await client.addRemote(name: "origin", url: bare.path(percentEncoded: false), in: repository)
    _ = try await client.createTag(named: "v1.0.0", target: nil, in: repository)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let tags = await store.tags
    let remotes = await store.tagPushRemotes
    let tag = try XCTUnwrap(tags.first { $0.shortName == "v1.0.0" })
    let remote = try XCTUnwrap(remotes.first { $0.name == "origin" })

    await store.pushTag(tag, to: remote)

    let remoteTags = try await client.git(["ls-remote", "--tags", bare.path(percentEncoded: false)], in: repo).stdout
    let commandResult = await store.commandResult
    XCTAssertTrue(remoteTags.contains("refs/tags/v1.0.0"))
    XCTAssertEqual(commandResult?.title, "Push tag v1.0.0")
    XCTAssertEqual(commandResult?.isError, false)

    await MainActor.run {
      store.presentDeleteRemoteTag(tag, from: remote)
    }
    let deleteRequest = await store.remoteTagDeleteRequest
    XCTAssertNotNil(deleteRequest)
    await store.deleteRequestedRemoteTag()

    let remainingRemoteTags = try await client.git(["ls-remote", "--tags", bare.path(percentEncoded: false)], in: repo).stdout
    let localTag = try await client.git(["rev-parse", "--verify", "refs/tags/v1.0.0"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let deleteResult = await store.commandResult
    XCTAssertFalse(remainingRemoteTags.contains("refs/tags/v1.0.0"))
    XCTAssertFalse(localTag.isEmpty)
    XCTAssertEqual(deleteResult?.title, "Delete tag v1.0.0 from origin")
    XCTAssertEqual(deleteResult?.isError, false)
  }

  func testStorePushesNonCurrentBranchToRemote() async throws {
    let repo = try await makeRepository()
    let bare = try await makeBareRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    try write("initial\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Initial")
    _ = try await client.addRemote(name: "origin", url: bare.path(percentEncoded: false), in: repository)
    _ = try await client.createBranch(named: "feature/publish", startPoint: nil, in: repository)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let branches = await store.localBranches
    let remotes = await store.branchPushRemotes
    let branch = try XCTUnwrap(branches.first { $0.shortName == "feature/publish" })
    let remote = try XCTUnwrap(remotes.first { $0.name == "origin" })

    await store.pushBranch(branch, to: remote)

    let remoteRefs = try await client.git(["ls-remote", "--heads", bare.path(percentEncoded: false)], in: repo).stdout
    let refs = try await client.refs(in: repository)
    let pushedBranch = try XCTUnwrap(refs.first { $0.shortName == "feature/publish" })
    let commandResult = await store.commandResult
    XCTAssertTrue(remoteRefs.contains("refs/heads/feature/publish"))
    XCTAssertEqual(pushedBranch.upstream, "origin/feature/publish")
    XCTAssertEqual(commandResult?.title, "Push branch feature/publish")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStorePullsNonCurrentLocalBranchFromUpstream() async throws {
    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    let sourceRepository = GitRepository(path: source.path(percentEncoded: false))
    try write("seed\n", to: source.appending(path: "README.md"))
    try await commitAll(in: source, message: "Seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)
    _ = try await client.git(["symbolic-ref", "HEAD", "refs/heads/main"], in: remote)
    _ = try await client.createBranch(named: "feature/pull-target", startPoint: nil, in: sourceRepository)
    _ = try await client.checkout("feature/pull-target", in: sourceRepository)
    try write("one\n", to: source.appending(path: "feature.txt"))
    try await commitAll(in: source, message: "Feature seed")
    _ = try await client.runRaw(["push", "-u", "origin", "feature/pull-target"], in: sourceRepository)

    let clone = temporaryDirectory()
    _ = try await client.cloneRepository(from: remote.path(percentEncoded: false), to: clone)
    let cloneRepository = GitRepository(path: clone.path(percentEncoded: false))
    var refs = try await client.refs(in: cloneRepository)
    let remoteFeature = try XCTUnwrap(refs.first { $0.shortName == "origin/feature/pull-target" && $0.kind == .remoteBranch })
    _ = try await client.checkoutTrackingRemote(remoteFeature, in: cloneRepository)
    _ = try await client.checkout("main", in: cloneRepository)
    refs = try await client.refs(in: cloneRepository)
    let oldLocalFeature = try XCTUnwrap(refs.first { $0.shortName == "feature/pull-target" && $0.kind == .localBranch })

    try write("two\n", to: source.appending(path: "feature.txt"))
    try await commitAll(in: source, message: "Feature update")
    _ = try await client.git(["push", "origin", "feature/pull-target"], in: source)
    let newHash = try await client.git(["rev-parse", "--short", "HEAD"], in: source).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let store = await RepositoryStore()
    await store.openRepository(at: clone)
    let branches = await store.localBranches
    let branch = try XCTUnwrap(branches.first { $0.shortName == "feature/pull-target" })

    await store.pullBranch(branch)

    let currentBranch = try await client.git(["branch", "--show-current"], in: clone).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    refs = try await client.refs(in: cloneRepository)
    let updatedLocalFeature = try XCTUnwrap(refs.first { $0.shortName == "feature/pull-target" && $0.kind == .localBranch })
    let updatedRemoteFeature = try XCTUnwrap(refs.first { $0.shortName == "origin/feature/pull-target" && $0.kind == .remoteBranch })
    let commandResult = await store.commandResult
    XCTAssertEqual(currentBranch, "main")
    XCTAssertNotEqual(updatedLocalFeature.objectName, oldLocalFeature.objectName)
    XCTAssertEqual(updatedLocalFeature.objectName, newHash)
    XCTAssertEqual(updatedRemoteFeature.objectName, newHash)
    XCTAssertEqual(commandResult?.title, "Pull feature/pull-target")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreMergesLocalBranchIntoCurrentBranch() async throws {
    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    try write("base\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Base")
    _ = try await client.createBranch(named: "feature/merge-source", startPoint: nil, in: repository)
    _ = try await client.checkout("feature/merge-source", in: repository)
    try write("feature\n", to: repo.appending(path: "feature.txt"))
    try await commitAll(in: repo, message: "Feature work")
    _ = try await client.checkout("main", in: repository)
    try write("main\n", to: repo.appending(path: "main.txt"))
    try await commitAll(in: repo, message: "Main work")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let branches = await store.localBranches
    let sourceBranch = try XCTUnwrap(branches.first { $0.shortName == "feature/merge-source" })

    await store.mergeReference(sourceBranch)

    let currentBranch = try await client.git(["branch", "--show-current"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let featureFile = try String(contentsOf: repo.appending(path: "feature.txt"), encoding: .utf8)
    let commandResult = await store.commandResult
    XCTAssertEqual(currentBranch, "main")
    XCTAssertEqual(featureFile, "feature\n")
    XCTAssertEqual(commandResult?.title, "Merge feature/merge-source")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreRebasesCurrentBranchOntoLocalBranch() async throws {
    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    try write("base\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Base")
    _ = try await client.createBranch(named: "feature/rebase-target", startPoint: nil, in: repository)
    _ = try await client.checkout("feature/rebase-target", in: repository)
    try write("target\n", to: repo.appending(path: "target.txt"))
    try await commitAll(in: repo, message: "Target work")
    _ = try await client.checkout("main", in: repository)
    try write("main\n", to: repo.appending(path: "main.txt"))
    try await commitAll(in: repo, message: "Main work")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let branches = await store.localBranches
    let targetBranch = try XCTUnwrap(branches.first { $0.shortName == "feature/rebase-target" })

    await store.rebaseOntoReference(targetBranch)

    let currentBranch = try await client.git(["branch", "--show-current"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let mergeBase = try await client.git(["merge-base", "main", "feature/rebase-target"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let targetHash = try await client.git(["rev-parse", "feature/rebase-target"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let commandResult = await store.commandResult
    XCTAssertEqual(currentBranch, "main")
    XCTAssertEqual(mergeBase, targetHash)
    XCTAssertEqual(commandResult?.title, "Rebase onto feature/rebase-target")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreMergesRemoteBranchIntoCurrentBranch() async throws {
    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    try write("base\n", to: source.appending(path: "README.md"))
    try await commitAll(in: source, message: "Base")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)
    _ = try await client.git(["checkout", "-b", "feature/remote-merge"], in: source)
    try write("remote\n", to: source.appending(path: "remote.txt"))
    try await commitAll(in: source, message: "Remote branch work")
    _ = try await client.git(["push", "-u", "origin", "feature/remote-merge"], in: source)
    _ = try await client.git(["symbolic-ref", "HEAD", "refs/heads/main"], in: remote)

    let clone = temporaryDirectory()
    _ = try await client.cloneRepository(from: remote.path(percentEncoded: false), to: clone)
    _ = try await client.git(["config", "user.name", "Bonsai Tests"], in: clone)
    _ = try await client.git(["config", "user.email", "bonsai@example.test"], in: clone)
    let cloneRepository = GitRepository(path: clone.path(percentEncoded: false))
    try write("main\n", to: clone.appending(path: "main.txt"))
    try await commitAll(in: clone, message: "Main work")

    let store = await RepositoryStore()
    await store.openRepository(at: clone)
    let remoteBranches = await store.remoteBranches
    let remoteBranch = try XCTUnwrap(remoteBranches.first { $0.shortName == "origin/feature/remote-merge" })

    await store.mergeReference(remoteBranch)

    let currentBranch = try await client.git(["branch", "--show-current"], in: clone).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let remoteFile = try String(contentsOf: clone.appending(path: "remote.txt"), encoding: .utf8)
    let commandResult = await store.commandResult
    XCTAssertEqual(currentBranch, "main")
    XCTAssertEqual(remoteFile, "remote\n")
    XCTAssertEqual(commandResult?.title, "Merge origin/feature/remote-merge")
    XCTAssertEqual(commandResult?.isError, false)
    let refs = try await client.refs(in: cloneRepository)
    XCTAssertTrue(refs.contains { $0.shortName == "origin/feature/remote-merge" })
  }

  func testStoreRebasesCurrentBranchOntoRemoteBranch() async throws {
    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    try write("base\n", to: source.appending(path: "README.md"))
    try await commitAll(in: source, message: "Base")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)
    _ = try await client.git(["checkout", "-b", "feature/remote-rebase"], in: source)
    try write("remote\n", to: source.appending(path: "remote.txt"))
    try await commitAll(in: source, message: "Remote branch work")
    _ = try await client.git(["push", "-u", "origin", "feature/remote-rebase"], in: source)
    _ = try await client.git(["symbolic-ref", "HEAD", "refs/heads/main"], in: remote)

    let clone = temporaryDirectory()
    _ = try await client.cloneRepository(from: remote.path(percentEncoded: false), to: clone)
    _ = try await client.git(["config", "user.name", "Bonsai Tests"], in: clone)
    _ = try await client.git(["config", "user.email", "bonsai@example.test"], in: clone)
    try write("main\n", to: clone.appending(path: "main.txt"))
    try await commitAll(in: clone, message: "Main work")

    let store = await RepositoryStore()
    await store.openRepository(at: clone)
    let remoteBranches = await store.remoteBranches
    let remoteBranch = try XCTUnwrap(remoteBranches.first { $0.shortName == "origin/feature/remote-rebase" })

    await store.rebaseOntoReference(remoteBranch)

    let currentBranch = try await client.git(["branch", "--show-current"], in: clone).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let mergeBase = try await client.git(["merge-base", "main", "origin/feature/remote-rebase"], in: clone).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let remoteHash = try await client.git(["rev-parse", "origin/feature/remote-rebase"], in: clone).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let commandResult = await store.commandResult
    XCTAssertEqual(currentBranch, "main")
    XCTAssertEqual(mergeBase, remoteHash)
    XCTAssertEqual(commandResult?.title, "Rebase onto origin/feature/remote-rebase")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreMergesTagIntoCurrentBranch() async throws {
    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    try write("base\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Base")
    _ = try await client.git(["checkout", "-b", "feature/tag-merge"], in: repo)
    try write("tagged\n", to: repo.appending(path: "tagged.txt"))
    try await commitAll(in: repo, message: "Tagged work")
    _ = try await client.createTag(named: "v-tag-merge", target: nil, in: repository)
    _ = try await client.checkout("main", in: repository)
    try write("main\n", to: repo.appending(path: "main.txt"))
    try await commitAll(in: repo, message: "Main work")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let tags = await store.tags
    let tag = try XCTUnwrap(tags.first { $0.shortName == "v-tag-merge" })

    await store.mergeReference(tag)

    let currentBranch = try await client.git(["branch", "--show-current"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let taggedFile = try String(contentsOf: repo.appending(path: "tagged.txt"), encoding: .utf8)
    let commandResult = await store.commandResult
    XCTAssertEqual(currentBranch, "main")
    XCTAssertEqual(taggedFile, "tagged\n")
    XCTAssertEqual(commandResult?.title, "Merge v-tag-merge")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreRebasesCurrentBranchOntoTag() async throws {
    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    try write("base\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Base")
    _ = try await client.git(["checkout", "-b", "feature/tag-rebase"], in: repo)
    try write("tagged\n", to: repo.appending(path: "tagged.txt"))
    try await commitAll(in: repo, message: "Tagged work")
    _ = try await client.createTag(named: "v-tag-rebase", target: nil, in: repository)
    _ = try await client.checkout("main", in: repository)
    try write("main\n", to: repo.appending(path: "main.txt"))
    try await commitAll(in: repo, message: "Main work")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let tags = await store.tags
    let tag = try XCTUnwrap(tags.first { $0.shortName == "v-tag-rebase" })

    await store.rebaseOntoReference(tag)

    let currentBranch = try await client.git(["branch", "--show-current"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let mergeBase = try await client.git(["merge-base", "main", "v-tag-rebase"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let tagHash = try await client.git(["rev-parse", "v-tag-rebase"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let commandResult = await store.commandResult
    XCTAssertEqual(currentBranch, "main")
    XCTAssertEqual(mergeBase, tagHash)
    XCTAssertEqual(commandResult?.title, "Rebase onto v-tag-rebase")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreFetchesSelectedRemoteBranch() async throws {
    let remote = try await makeBareRepository()
    let source = try await makeRepository()
    try write("seed\n", to: source.appending(path: "README.md"))
    try await commitAll(in: source, message: "Seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: source)
    _ = try await client.git(["push", "-u", "origin", "main"], in: source)
    _ = try await client.git(["symbolic-ref", "HEAD", "refs/heads/main"], in: remote)

    let clone = temporaryDirectory()
    _ = try await client.cloneRepository(from: remote.path(percentEncoded: false), to: clone)
    let cloneRepository = GitRepository(path: clone.path(percentEncoded: false))
    let refsBefore = try await client.refs(in: cloneRepository)
    let oldRemoteMain = try XCTUnwrap(refsBefore.first { $0.shortName == "origin/main" && $0.kind == .remoteBranch })

    try write("remote update\n", to: source.appending(path: "remote.txt"))
    try await commitAll(in: source, message: "Remote update")
    _ = try await client.git(["push", "origin", "main"], in: source)
    let newHash = try await client.git(["rev-parse", "--short", "HEAD"], in: source).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let store = await RepositoryStore()
    await store.openRepository(at: clone)
    let remoteBranches = await store.remoteBranches
    let remoteMain = try XCTUnwrap(remoteBranches.first { $0.shortName == "origin/main" })

    await store.fetchRemoteBranch(remoteMain)

    let refsAfter = try await client.refs(in: cloneRepository)
    let updatedRemoteMain = try XCTUnwrap(refsAfter.first { $0.shortName == "origin/main" && $0.kind == .remoteBranch })
    let commandResult = await store.commandResult
    XCTAssertNotEqual(updatedRemoteMain.objectName, oldRemoteMain.objectName)
    XCTAssertEqual(updatedRemoteMain.objectName, newHash)
    XCTAssertEqual(commandResult?.title, "Fetch origin/main")
    XCTAssertEqual(commandResult?.isError, false)
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
    let diff = try await client.diffForWorkingTreeFile(entry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)
    let firstHunk = try XCTUnwrap(GitParsers.parseDiffHunks(diff).first)
    let firstLineChange = try XCTUnwrap(GitParsers.parseDiffLineChanges(firstHunk).first)

    _ = try await client.stageLineChange(firstLineChange, in: repository)

    let status = try await client.status(in: repository)
    let stagedEntry = try XCTUnwrap(status.first { $0.isStaged })
    let unstagedEntry = try XCTUnwrap(status.first { !$0.isStaged })
    let stagedDiff = try await client.diffForWorkingTreeFile(stagedEntry, staged: true, algorithm: .histogram, whitespaceMode: .show, in: repository)
    let unstagedDiff = try await client.diffForWorkingTreeFile(unstagedEntry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)

    XCTAssertTrue(stagedDiff.contains("line two changed"))
    XCTAssertFalse(stagedDiff.contains("line eighteen changed"))
    XCTAssertTrue(unstagedDiff.contains("line eighteen changed"))

    _ = try await client.unstageLineChange(firstLineChange, in: repository)
    let finalStatus = try await client.status(in: repository)
    XCTAssertFalse(finalStatus.contains { $0.isStaged })
    let finalEntry = try XCTUnwrap(finalStatus.first)
    let finalDiff = try await client.diffForWorkingTreeFile(finalEntry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)
    XCTAssertTrue(finalDiff.contains("line two changed"))
    XCTAssertTrue(finalDiff.contains("line eighteen changed"))
  }

  func testDiscardHunkLeavesOtherHunksInWorkingTree() async throws {
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
    let status = try await client.status(in: repository)
    let entry = try XCTUnwrap(status.first)
    let diff = try await client.diffForWorkingTreeFile(entry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)
    let hunks = GitParsers.parseDiffHunks(diff)
    XCTAssertGreaterThanOrEqual(hunks.count, 2)

    _ = try await client.discardHunk(hunks[0], in: repository)

    let text = try String(contentsOf: file, encoding: .utf8)
    XCTAssertTrue(text.contains("line 2\n"))
    XCTAssertFalse(text.contains("line two changed"))
    XCTAssertTrue(text.contains("line twenty changed"))

    let remainingStatus = try await client.status(in: repository)
    let remainingEntry = try XCTUnwrap(remainingStatus.first)
    let remainingDiff = try await client.diffForWorkingTreeFile(remainingEntry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)
    XCTAssertFalse(remainingDiff.contains("line two changed"))
    XCTAssertTrue(remainingDiff.contains("line twenty changed"))
  }

  func testDiscardLineChangeLeavesOtherLineChangesInWorkingTree() async throws {
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
    let status = try await client.status(in: repository)
    let entry = try XCTUnwrap(status.first)
    let diff = try await client.diffForWorkingTreeFile(entry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)
    let firstHunk = try XCTUnwrap(GitParsers.parseDiffHunks(diff).first)
    let firstLineChange = try XCTUnwrap(GitParsers.parseDiffLineChanges(firstHunk).first)

    _ = try await client.discardLineChange(firstLineChange, in: repository)

    let text = try String(contentsOf: file, encoding: .utf8)
    XCTAssertTrue(text.contains("line 2\n"))
    XCTAssertFalse(text.contains("line two changed"))
    XCTAssertTrue(text.contains("line eighteen changed"))

    let remainingStatus = try await client.status(in: repository)
    let remainingEntry = try XCTUnwrap(remainingStatus.first)
    let remainingDiff = try await client.diffForWorkingTreeFile(remainingEntry, staged: false, algorithm: .histogram, whitespaceMode: .show, in: repository)
    XCTAssertFalse(remainingDiff.contains("line two changed"))
    XCTAssertTrue(remainingDiff.contains("line eighteen changed"))
  }

  func testApplyPatchUsesGitPatchEngine() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "README.md")
    try write("before\n", to: file)
    try await commitAll(in: repo, message: "Initial")

    try write("after\n", to: file)
    let patch = try await client.git(["diff", "--", "README.md"], in: repo).stdout
    _ = try await client.git(["restore", "--", "README.md"], in: repo)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    _ = try await client.applyPatch(patch, in: repository)

    XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "after\n")
  }

  func testStoreConfirmsPatchBeforeApplyingClipboardText() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "README.md")
    try write("before\n", to: file)
    try await commitAll(in: repo, message: "Initial")

    try write("after\n", to: file)
    let patch = try await client.git(["diff", "--", "README.md"], in: repo).stdout
    _ = try await client.git(["restore", "--", "README.md"], in: repo)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(patch, forType: .string)
      store.presentApplyPatchFromClipboard()
    }

    let request = await store.applyPatchRequest
    XCTAssertEqual(request?.patch, patch)
    XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "before\n")

    await store.applyRequestedPatch()

    let commandResult = await store.commandResult
    let clearedRequest = await store.applyPatchRequest
    XCTAssertNil(clearedRequest)
    XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "after\n")
    XCTAssertEqual(commandResult?.title, "Apply patch")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreReportsEmptyClipboardBeforePatchConfirmation() async throws {
    let repo = try await makeRepository()
    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      NSPasteboard.general.clearContents()
      store.presentApplyPatchFromClipboard()
    }

    let commandResult = await store.commandResult
    let request = await store.applyPatchRequest
    let errorMessage = await store.errorMessage
    XCTAssertNil(request)
    XCTAssertEqual(commandResult?.title, "Apply patch")
    XCTAssertEqual(commandResult?.isError, true)
    XCTAssertEqual(errorMessage, "The clipboard does not contain patch text.")
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

  func testImageDiffSnapshotsReadStashBlobs() async throws {
    let repo = try await makeRepository()
    let image = repo.appending(path: "image.png")
    let firstImage = try XCTUnwrap(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="))
    let secondImage = try XCTUnwrap(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR42mNk+M8AAwUBAZsJTYQAAAAASUVORK5CYII="))

    try write(firstImage, to: image)
    try await commitAll(in: repo, message: "Initial image")
    try write(secondImage, to: image)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    _ = try await client.stashPush(message: "image stash", in: repository)
    let stashes = try await client.stashes(in: repository)
    let stash = try XCTUnwrap(stashes.first)
    let changedFiles = try await client.changedFiles(in: repository, stash: stash)
    let changedFile = try XCTUnwrap(changedFiles.first { $0.path == "image.png" })

    let snapshot = await client.imageDiffForStashFile(changedFile, stash: stash, in: repository)
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

  func testStoreDiscardsAllUnstagedChangesAfterConfirmation() async throws {
    let repo = try await makeRepository()
    let trackedFile = repo.appending(path: "file.txt")
    let stagedFile = repo.appending(path: "staged.txt")
    let scratch = repo.appending(path: "scratch.txt")
    let ignored = repo.appending(path: "ignored.log")
    try write("*.log\n", to: repo.appending(path: ".gitignore"))
    try write("original\n", to: trackedFile)
    try write("staged original\n", to: stagedFile)
    try await commitAll(in: repo, message: "Initial files")

    try write("changed\n", to: trackedFile)
    try write("staged changed\n", to: stagedFile)
    try write("scratch\n", to: scratch)
    try write("ignored\n", to: ignored)

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let stagedStatus = try await client.status(in: repository).first { $0.path == "staged.txt" }
    _ = try await client.stage(try XCTUnwrap(stagedStatus), in: repository)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.presentDiscardUnstagedChanges()
    }

    let requestValue = await store.discardUnstagedChangesRequest
    let request = try XCTUnwrap(requestValue)
    XCTAssertEqual(request.changeCount, 2)
    XCTAssertEqual(request.trackedCount, 1)
    XCTAssertEqual(request.untrackedCount, 1)
    XCTAssertTrue(request.entries.contains { $0.path == "file.txt" })
    XCTAssertTrue(request.entries.contains { $0.path == "scratch.txt" })
    XCTAssertFalse(request.entries.contains { $0.path == "staged.txt" })
    XCTAssertFalse(request.entries.contains { $0.path == "ignored.log" })

    await store.discardUnstagedChanges()

    XCTAssertEqual(try String(contentsOf: trackedFile, encoding: .utf8), "original\n")
    XCTAssertFalse(FileManager.default.fileExists(atPath: scratch.path(percentEncoded: false)))
    XCTAssertTrue(FileManager.default.fileExists(atPath: ignored.path(percentEncoded: false)))

    let status = try await client.status(in: repository, includeIgnoredFiles: true)
    XCTAssertTrue(status.contains { $0.path == "staged.txt" && $0.isStaged })
    XCTAssertTrue(status.contains { $0.path == "ignored.log" && $0.isIgnored })
    XCTAssertFalse(status.contains { $0.path == "file.txt" })
    XCTAssertFalse(status.contains { $0.path == "scratch.txt" })
  }

  func testStoreIgnoresUntrackedFile() async throws {
    let repo = try await makeRepository()
    try write("tracked\n", to: repo.appending(path: "tracked.txt"))
    try await commitAll(in: repo, message: "Initial")
    try write("cache\n", to: repo.appending(path: "DerivedData/cache.log"))

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.mainMode = .changes
      store.selectedStatusEntry = store.snapshot.status.first { $0.path == "DerivedData/cache.log" }
    }

    await store.ignoreSelectedStatusEntry()

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let ignoreText = try String(contentsOf: repo.appending(path: ".gitignore"), encoding: .utf8)
    let status = try await client.status(in: repository)
    let commandResult = await store.commandResult
    XCTAssertTrue(ignoreText.contains("/DerivedData/cache.log\n"))
    XCTAssertFalse(status.contains { $0.path == "DerivedData/cache.log" })
    XCTAssertEqual(commandResult?.title, "Ignore DerivedData/cache.log")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreIgnoresUntrackedExtension() async throws {
    let repo = try await makeRepository()
    try write("tracked\n", to: repo.appending(path: "tracked.txt"))
    try await commitAll(in: repo, message: "Initial")
    try write("one\n", to: repo.appending(path: "Logs/one.log"))
    try write("two\n", to: repo.appending(path: "Logs/two.log"))
    try write("note\n", to: repo.appending(path: "Logs/note.txt"))

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.mainMode = .changes
      store.selectedStatusEntry = store.snapshot.status.first { $0.path == "Logs/one.log" }
    }

    await store.ignoreSelectedStatusEntryExtension()

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let ignoreText = try String(contentsOf: repo.appending(path: ".gitignore"), encoding: .utf8)
    let status = try await client.status(in: repository)
    let commandResult = await store.commandResult
    XCTAssertTrue(ignoreText.contains("*.log\n"))
    XCTAssertFalse(status.contains { $0.path.hasSuffix(".log") })
    XCTAssertTrue(status.contains { $0.path == "Logs/note.txt" })
    XCTAssertEqual(commandResult?.title, "Ignore *.log")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreIgnoresUntrackedFolder() async throws {
    let repo = try await makeRepository()
    try write("tracked\n", to: repo.appending(path: "tracked.txt"))
    try await commitAll(in: repo, message: "Initial")
    try write("one\n", to: repo.appending(path: "Logs/one.log"))
    try write("two\n", to: repo.appending(path: "Logs/two.tmp"))
    try write("note\n", to: repo.appending(path: "Notes/note.txt"))

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.mainMode = .changes
      store.selectedStatusEntry = store.snapshot.status.first { $0.path == "Logs/one.log" }
    }

    await store.ignoreSelectedStatusEntryDirectory()

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let ignoreText = try String(contentsOf: repo.appending(path: ".gitignore"), encoding: .utf8)
    let status = try await client.status(in: repository)
    let commandResult = await store.commandResult
    XCTAssertTrue(ignoreText.contains("/Logs/\n"))
    XCTAssertFalse(status.contains { $0.path.hasPrefix("Logs/") })
    XCTAssertTrue(status.contains { $0.path == "Notes/note.txt" })
    XCTAssertEqual(commandResult?.title, "Ignore /Logs/")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testStoreAppliesGitIgnoreTemplateAndSkipsExistingPatterns() async throws {
    let repo = try await makeRepository()
    try write("tracked\n", to: repo.appending(path: "tracked.txt"))
    try await commitAll(in: repo, message: "Initial")
    try write("# Local notes\nnode_modules/\n", to: repo.appending(path: ".gitignore"))
    try write("cache\n", to: repo.appending(path: "node_modules/pkg/index.js"))
    try write("secret\n", to: repo.appending(path: ".env.local"))

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    await MainActor.run {
      store.selectedGitIgnoreTemplateID = "node"
      store.presentGitIgnoreTemplatePicker()
    }

    await store.applySelectedGitIgnoreTemplate()

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let ignoreText = try String(contentsOf: repo.appending(path: ".gitignore"), encoding: .utf8)
    let status = try await client.status(in: repository)
    let commandResult = await store.commandResult
    XCTAssertEqual(ignoreText.components(separatedBy: "node_modules/").count - 1, 1)
    XCTAssertTrue(ignoreText.contains("# Local notes\nnode_modules/\n"))
    XCTAssertTrue(ignoreText.contains("# Node\n"))
    XCTAssertTrue(ignoreText.contains(".env.local\n"))
    XCTAssertFalse(status.contains { $0.path.hasPrefix("node_modules/") })
    XCTAssertFalse(status.contains { $0.path == ".env.local" })
    XCTAssertEqual(commandResult?.title, "Add Node .gitignore")
    XCTAssertEqual(commandResult?.isError, false)
  }

  func testReflogEntryCanResetHeadToPreviousCommit() async throws {
    let repo = try await makeRepository()
    try write("one\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "First")
    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let firstHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)

    try write("two\n", to: repo.appending(path: "file.txt"))
    try await commitAll(in: repo, message: "Second")

    let entries = try await client.reflogEntries(in: repository)
    let firstEntry = try XCTUnwrap(entries.first { $0.hash == firstHash })
    _ = try await client.reset(to: firstEntry, mode: .hard, in: repository)
    let currentHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)

    XCTAssertEqual(currentHash, firstHash)
  }

  func testInProgressOperationStatusSupportsMergeAbortAndCherryPickSkip() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "story.txt")
    try write("base\n", to: file)
    try await commitAll(in: repo, message: "Base")

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    _ = try await client.createBranch(named: "side", startPoint: nil, in: repository)
    _ = try await client.checkout("side", in: repository)
    try write("side\n", to: file)
    try await commitAll(in: repo, message: "Side change")
    let sideHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)

    _ = try await client.checkout("main", in: repository)
    try write("main\n", to: file)
    try await commitAll(in: repo, message: "Main change")

    let sideCommit = try await client.commit(revision: sideHash, in: repository)

    do {
      _ = try await client.runRevisionCommand(.merge, commit: sideCommit, in: repository)
      XCTFail("Expected merge conflict")
    } catch {
      var operation = try await client.snapshot(for: repository, selectedCommit: nil).inProgressOperation
      XCTAssertEqual(operation.kind, .merge)
      XCTAssertFalse(operation.kind?.canSkip ?? true)
      _ = try await client.runInProgressOperation(.abort, kind: .merge, in: repository)
      operation = try await client.snapshot(for: repository, selectedCommit: nil).inProgressOperation
      XCTAssertFalse(operation.active)
    }

    do {
      _ = try await client.runRevisionCommand(.cherryPick, commit: sideCommit, in: repository)
      XCTFail("Expected cherry-pick conflict")
    } catch {
      var operation = try await client.snapshot(for: repository, selectedCommit: nil).inProgressOperation
      XCTAssertEqual(operation.kind, .cherryPick)
      XCTAssertTrue(operation.kind?.canSkip ?? false)
      _ = try await client.runInProgressOperation(.skip, kind: .cherryPick, in: repository)
      operation = try await client.snapshot(for: repository, selectedCommit: nil).inProgressOperation
      XCTAssertFalse(operation.active)
    }
  }

  func testBisectWorkflowTracksActiveStateAndMarksRevisions() async throws {
    let repo = try await makeRepository()
    let file = repo.appending(path: "file.txt")
    for index in 1...5 {
      try write("\(index)\n", to: file)
      try await commitAll(in: repo, message: "Commit \(index)")
    }

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let goodHash = try await client.git(["rev-list", "--max-parents=0", "HEAD"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let badHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout.trimmingCharacters(in: .whitespacesAndNewlines)

    var bisect = await client.integrations(in: repository).bisect
    XCTAssertFalse(bisect.active)

    _ = try await client.startBisect(bad: badHash, good: goodHash, in: repository)
    bisect = await client.integrations(in: repository).bisect
    XCTAssertTrue(bisect.active)
    XCTAssertEqual(bisect.badRevision, badHash)
    XCTAssertTrue(bisect.goodRevisions.contains(goodHash))
    XCTAssertFalse(bisect.currentShortHash?.isEmpty ?? true)

    let skippedHash = try XCTUnwrap(bisect.currentHash)
    _ = try await client.markBisect(.skip, in: repository)
    bisect = await client.integrations(in: repository).bisect
    XCTAssertTrue(bisect.active)
    XCTAssertTrue(bisect.skippedRevisions.contains(skippedHash))

    _ = try await client.resetBisect(in: repository)
    _ = try await client.startBisect(bad: badHash, good: goodHash, in: repository)
    bisect = await client.integrations(in: repository).bisect
    XCTAssertTrue(bisect.active)

    _ = try await client.markBisect(.good, in: repository)
    bisect = await client.integrations(in: repository).bisect
    XCTAssertTrue(bisect.active)
    XCTAssertGreaterThanOrEqual(bisect.goodRevisions.count, 2)

    _ = try await client.markBisect(.bad, in: repository)
    bisect = await client.integrations(in: repository).bisect
    XCTAssertTrue(bisect.active)
    XCTAssertNotEqual(bisect.badRevision, badHash)

    _ = try await client.resetBisect(in: repository)
    bisect = await client.integrations(in: repository).bisect
    XCTAssertFalse(bisect.active)
  }

  func testRefsStashesRemotesAndRepositoryActions() async throws {
    let remote = try await makeBareRepository()
    let repo = try await makeRepository()
    let repository = GitRepository(path: repo.path(percentEncoded: false))

    try write("seed\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: repo)
    _ = try await client.git(["push", "-u", "origin", "main"], in: repo)
    _ = try await client.createBranch(named: "feature/remote", startPoint: nil, in: repository)
    _ = try await client.checkout("feature/remote", in: repository)
    try write("remote branch\n", to: repo.appending(path: "remote.txt"))
    try await commitAll(in: repo, message: "Remote branch")
    _ = try await client.runRaw(["push", "-u", "origin", "feature/remote"], in: repository)
    _ = try await client.checkout("main", in: repository)
    _ = try await client.deleteBranch("feature/remote", force: false, in: repository)

    try write("local ahead\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Local ahead")
    var refs = try await client.refs(in: repository)
    let mainBranch = try XCTUnwrap(refs.first { $0.shortName == "main" && $0.kind == .localBranch })
    XCTAssertEqual(mainBranch.ahead, 1)

    _ = try await client.runAction(.fetch, in: repository)
    _ = try await client.runAction(.pull, in: repository)
    _ = try await client.runAction(.push, in: repository)
    let remotes = try await client.remotes(in: repository)
    XCTAssertEqual(remotes.first?.name, "origin")
    refs = try await client.refs(in: repository)
    let pushedMain = try XCTUnwrap(refs.first { $0.shortName == "main" && $0.kind == .localBranch })
    XCTAssertEqual(pushedMain.upstream, "origin/main")
    _ = try await client.unsetUpstream(for: "main", in: repository)
    refs = try await client.refs(in: repository)
    XCTAssertNil(refs.first { $0.shortName == "main" && $0.kind == .localBranch }?.upstream)
    _ = try await client.setUpstream("origin/main", for: "main", in: repository)
    refs = try await client.refs(in: repository)
    XCTAssertEqual(refs.first { $0.shortName == "main" && $0.kind == .localBranch }?.upstream, "origin/main")

    _ = try await client.createBranch(named: "feature/publish", startPoint: nil, in: repository)
    _ = try await client.checkout("feature/publish", in: repository)
    try write("publish\n", to: repo.appending(path: "publish.txt"))
    try await commitAll(in: repo, message: "Publish branch")
    let publishStore = await RepositoryStore()
    await publishStore.openRepository(at: repo)
    let pushActionTitle = await publishStore.pushActionTitle
    XCTAssertEqual(pushActionTitle, "Publish")
    await publishStore.runRepositoryAction(.push)
    let publishError = await publishStore.errorMessage
    XCTAssertNil(publishError)
    refs = try await client.refs(in: repository)
    XCTAssertEqual(refs.first { $0.shortName == "feature/publish" && $0.kind == .localBranch }?.upstream, "origin/feature/publish")
    XCTAssertTrue(refs.contains { $0.shortName == "origin/feature/publish" && $0.kind == .remoteBranch })
    _ = try await client.checkout("main", in: repository)

    let forcePushStore = await RepositoryStore()
    await forcePushStore.openRepository(at: repo)
    await MainActor.run {
      forcePushStore.presentForcePushCurrentBranch()
    }
    let forcePushRequest = await forcePushStore.forcePushRequest
    XCTAssertNotNil(forcePushRequest)
    await MainActor.run {
      forcePushStore.forcePushRequest = nil
    }

    let createBranchStore = await RepositoryStore()
    await createBranchStore.openRepository(at: repo)
    let localBranchRefs = await createBranchStore.localBranches
    let publishLocalRef = try XCTUnwrap(localBranchRefs.first { $0.shortName == "feature/publish" })
    await MainActor.run {
      createBranchStore.presentCreateBranch(from: publishLocalRef)
      createBranchStore.operationInput = "feature/from-local"
    }
    await createBranchStore.confirmOperation()
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "feature/from-local" && $0.kind == .localBranch })
    await MainActor.run {
      createBranchStore.presentCreateTag(from: publishLocalRef)
      createBranchStore.operationInput = "local-ref-tag"
    }
    await createBranchStore.confirmOperation()
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "local-ref-tag" && $0.kind == .tag })

    _ = try await client.createBranch(named: "feature/delete-remote", startPoint: nil, in: repository)
    _ = try await client.checkout("feature/delete-remote", in: repository)
    try write("delete remote\n", to: repo.appending(path: "delete-remote.txt"))
    try await commitAll(in: repo, message: "Delete remote branch")
    _ = try await client.runRaw(["push", "-u", "origin", "feature/delete-remote"], in: repository)
    _ = try await client.checkout("main", in: repository)
    _ = try await client.deleteBranch("feature/delete-remote", force: true, in: repository)
    let deleteRemoteStore = await RepositoryStore()
    await deleteRemoteStore.openRepository(at: repo)
    let remoteBranches = await deleteRemoteStore.remoteBranches
    let remoteBranchToDelete = try XCTUnwrap(remoteBranches.first { $0.shortName == "origin/feature/delete-remote" })
    await MainActor.run {
      deleteRemoteStore.presentDelete(remoteBranchToDelete)
    }
    await deleteRemoteStore.deleteRequestedRef()
    refs = try await client.refs(in: repository)
    XCTAssertFalse(refs.contains { $0.shortName == "origin/feature/delete-remote" && $0.kind == .remoteBranch })

    let remoteFeature = try XCTUnwrap(refs.first { $0.shortName == "origin/feature/remote" && $0.kind == .remoteBranch })
    let createRemoteBranchStore = await RepositoryStore()
    await createRemoteBranchStore.openRepository(at: repo)
    let remoteBranchRefs = await createRemoteBranchStore.remoteBranches
    let remoteFeatureRef = try XCTUnwrap(remoteBranchRefs.first { $0.shortName == "origin/feature/remote" })
    await MainActor.run {
      createRemoteBranchStore.presentCreateBranch(from: remoteFeatureRef)
      createRemoteBranchStore.operationInput = "feature/from-remote"
    }
    await createRemoteBranchStore.confirmOperation()
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "feature/from-remote" && $0.kind == .localBranch })
    await MainActor.run {
      createRemoteBranchStore.presentCreateTag(from: remoteFeatureRef)
      createRemoteBranchStore.operationInput = "remote-ref-tag"
    }
    await createRemoteBranchStore.confirmOperation()
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "remote-ref-tag" && $0.kind == .tag })

    XCTAssertEqual(remoteFeature.remoteTrackingLocalName, "feature/remote")
    _ = try await client.checkoutTrackingRemote(remoteFeature, in: repository)
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "feature/remote" && $0.kind == .localBranch && $0.upstream == "origin/feature/remote" })
    _ = try await client.checkout("main", in: repository)
    _ = try await client.deleteBranch("feature/remote", force: false, in: repository)

    _ = try await client.createBranch(named: "feature/test", startPoint: nil, in: repository)
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "feature/test" })
    _ = try await client.renameBranch(from: "feature/test", to: "feature/renamed", in: repository)
    refs = try await client.refs(in: repository)
    XCTAssertFalse(refs.contains { $0.shortName == "feature/test" })
    XCTAssertTrue(refs.contains { $0.shortName == "feature/renamed" })
    _ = try await client.checkout("feature/renamed", in: repository)
    _ = try await client.checkout("main", in: repository)
    _ = try await client.deleteBranch("feature/renamed", force: false, in: repository)

    _ = try await client.createBranch(named: "feature/unmerged", startPoint: nil, in: repository)
    _ = try await client.checkout("feature/unmerged", in: repository)
    try write("unmerged\n", to: repo.appending(path: "unmerged.txt"))
    try await commitAll(in: repo, message: "Unmerged branch")
    _ = try await client.checkout("main", in: repository)
    do {
      _ = try await client.deleteBranch("feature/unmerged", force: false, in: repository)
      XCTFail("Expected safe branch deletion to reject an unmerged branch")
    } catch {
      _ = try await client.deleteBranch("feature/unmerged", force: true, in: repository)
    }
    refs = try await client.refs(in: repository)
    XCTAssertFalse(refs.contains { $0.shortName == "feature/unmerged" })

    _ = try await client.createTag(named: "v0.1.0", target: nil, in: repository)
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "v0.1.0" })
    let createTagBranchStore = await RepositoryStore()
    await createTagBranchStore.openRepository(at: repo)
    let tagRefs = await createTagBranchStore.tags
    let tagRef = try XCTUnwrap(tagRefs.first { $0.shortName == "v0.1.0" })
    await MainActor.run {
      createTagBranchStore.presentCreateBranch(from: tagRef)
      createTagBranchStore.operationInput = "feature/from-tag"
    }
    await createTagBranchStore.confirmOperation()
    refs = try await client.refs(in: repository)
    XCTAssertTrue(refs.contains { $0.shortName == "feature/from-tag" && $0.kind == .localBranch })
    _ = try await client.deleteTag("v0.1.0", in: repository)

    try write("dirty\n", to: repo.appending(path: "README.md"))
    _ = try await client.stashPush(message: "save dirty readme", in: repository)
    var stashes = try await client.stashes(in: repository)
    let stash = try XCTUnwrap(stashes.first)
    let stashFiles = try await client.changedFiles(in: repository, stash: stash)
    let stashFile = try XCTUnwrap(stashFiles.first)
    let stashDiff = try await client.diffForStashFile(stashFile, stash: stash, algorithm: .histogram, whitespaceMode: .show, in: repository)
    let stashPatch = try await client.stashPatch(stash, algorithm: .histogram, whitespaceMode: .show, in: repository)
    XCTAssertEqual(stashFile.path, "README.md")
    XCTAssertTrue(stashDiff.contains("+dirty"))
    XCTAssertTrue(stashPatch.contains("diff --git a/README.md b/README.md"))
    XCTAssertTrue(stashPatch.contains("+dirty"))
    _ = try await client.stashApply(stash, pop: false, in: repository)
    _ = try await client.git(["checkout", "--", "README.md"], in: repo)
    _ = try await client.stashDrop(stash, in: repository)
    stashes = try await client.stashes(in: repository)
    XCTAssertTrue(stashes.isEmpty)

    try write("scratch\n", to: repo.appending(path: "scratch.txt"))
    _ = try await client.stashPush(message: "save scratch", includeUntracked: true, in: repository)
    XCTAssertFalse(FileManager.default.fileExists(atPath: repo.appending(path: "scratch.txt").path(percentEncoded: false)))
    stashes = try await client.stashes(in: repository)
    let untrackedStash = try XCTUnwrap(stashes.first { $0.message.contains("save scratch") })
    _ = try await client.stashApply(untrackedStash, pop: false, in: repository)
    XCTAssertEqual(try String(contentsOf: repo.appending(path: "scratch.txt"), encoding: .utf8), "scratch\n")
    _ = try await client.git(["clean", "-f", "--", "scratch.txt"], in: repo)
    _ = try await client.stashDrop(untrackedStash, in: repository)
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

    let branchWorktreeURL = temporaryDirectory()
    let branchWorktreePath = canonicalPath(branchWorktreeURL)
    _ = try await client.createWorktree(
      at: branchWorktreeURL.path(percentEncoded: false),
      startPoint: "HEAD",
      branch: "feature/worktree",
      in: repository
    )
    let branch = try await client.git(["branch", "--show-current"], in: branchWorktreeURL).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    XCTAssertEqual(branch, "feature/worktree")
    worktrees = try await client.worktrees(in: repository)
    let branchWorktree = try XCTUnwrap(worktrees.first { canonicalPath($0.path) == branchWorktreePath })
    XCTAssertEqual(branchWorktree.displayState, "feature/worktree")

    _ = try await client.removeWorktree(branchWorktree, in: repository)
    worktrees = try await client.worktrees(in: repository)
    XCTAssertFalse(worktrees.contains { canonicalPath($0.path) == branchWorktreePath })

    let dirtyWorktreeURL = temporaryDirectory()
    let dirtyWorktreePath = canonicalPath(dirtyWorktreeURL)
    _ = try await client.createWorktree(at: dirtyWorktreeURL.path(percentEncoded: false), startPoint: "HEAD", in: repository)
    try write("dirty\n", to: dirtyWorktreeURL.appending(path: "dirty.txt"))
    worktrees = try await client.worktrees(in: repository)
    let dirty = try XCTUnwrap(worktrees.first { canonicalPath($0.path) == dirtyWorktreePath })

    do {
      _ = try await client.removeWorktree(dirty, in: repository)
      XCTFail("Expected normal worktree removal to reject a dirty worktree")
    } catch {
      _ = try await client.removeWorktree(dirty, force: true, in: repository)
    }
    worktrees = try await client.worktrees(in: repository)
    XCTAssertFalse(worktrees.contains { canonicalPath($0.path) == dirtyWorktreePath })
  }

  func testPruneWorktreesRemovesMissingWorktreeAdministrativeEntry() async throws {
    let repo = try await makeRepository()
    try write("root\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Initial")

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let worktreeURL = temporaryDirectory()
    let worktreeName = worktreeURL.lastPathComponent
    _ = try await client.createWorktree(at: worktreeURL.path(percentEncoded: false), startPoint: "HEAD", in: repository)

    try FileManager.default.removeItem(at: worktreeURL)

    var worktrees = try await client.worktrees(in: repository)
    let staleWorktree = try XCTUnwrap(worktrees.first { $0.path.hasSuffix("/\(worktreeName)") })
    XCTAssertTrue(staleWorktree.isPrunable)

    _ = try await client.pruneWorktrees(in: repository)

    worktrees = try await client.worktrees(in: repository)
    XCTAssertFalse(worktrees.contains { $0.path.hasSuffix("/\(worktreeName)") })
  }

  func testStoreForcePushesCurrentBranchWithLease() async throws {
    let remote = try await makeBareRepository()
    let repo = try await makeRepository()

    try write("seed\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Seed")
    _ = try await client.git(["remote", "add", "origin", remote.path(percentEncoded: false)], in: repo)
    _ = try await client.git(["push", "-u", "origin", "main"], in: repo)

    try write("first\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "First")
    _ = try await client.git(["push", "origin", "main"], in: repo)

    try write("rewritten\n", to: repo.appending(path: "README.md"))
    _ = try await client.git(["add", "."], in: repo)
    _ = try await client.git(["commit", "--amend", "-m", "Rewritten"], in: repo)
    let localHash = try await client.git(["rev-parse", "HEAD"], in: repo).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let canForcePush = await store.canForcePushCurrentBranch
    XCTAssertTrue(canForcePush)
    await MainActor.run {
      store.presentForcePushCurrentBranch()
    }
    let pendingRequest = await store.forcePushRequest
    let request = try XCTUnwrap(pendingRequest)
    XCTAssertEqual(request.branch.shortName, "main")
    XCTAssertEqual(request.upstream, "origin/main")

    await store.forcePushRequestedBranch()

    let remoteHash = try await client.git(["rev-parse", "main"], in: remote).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let commandResult = await store.commandResult
    XCTAssertEqual(remoteHash, localHash)
    XCTAssertEqual(commandResult?.title, "Force push main")
    XCTAssertEqual(commandResult?.isError, false)
    let completedRequest = await store.forcePushRequest
    XCTAssertNil(completedRequest)
  }

  func testForcePushRequestRequiresUsableUpstream() async throws {
    let repo = try await makeRepository()
    try write("seed\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Seed")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)
    let canForcePush = await store.canForcePushCurrentBranch
    XCTAssertFalse(canForcePush)

    await MainActor.run {
      store.presentForcePushCurrentBranch()
    }

    let commandResult = await store.commandResult
    let request = await store.forcePushRequest
    XCTAssertNil(request)
    XCTAssertEqual(commandResult?.title, "Force push with lease")
    XCTAssertEqual(commandResult?.isError, true)
    XCTAssertEqual(commandResult?.output, "Set a usable upstream before force pushing.")
  }

  func testStorePrunesWorktreesAndRefreshesSnapshot() async throws {
    let repo = try await makeRepository()
    try write("root\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Initial")

    let repository = GitRepository(path: repo.path(percentEncoded: false))
    let worktreeURL = temporaryDirectory()
    let worktreeName = worktreeURL.lastPathComponent
    _ = try await client.createWorktree(at: worktreeURL.path(percentEncoded: false), startPoint: "HEAD", in: repository)

    let store = await RepositoryStore()
    await store.openRepository(at: repo)

    var snapshot = await store.snapshot
    XCTAssertTrue(snapshot.worktrees.contains { $0.path.hasSuffix("/\(worktreeName)") })

    try FileManager.default.removeItem(at: worktreeURL)

    await store.pruneWorktrees()

    snapshot = await store.snapshot
    let commandResult = await store.commandResult
    XCTAssertFalse(snapshot.worktrees.contains { $0.path.hasSuffix("/\(worktreeName)") })
    XCTAssertEqual(commandResult?.title, "Prune worktrees")
  }

  func testStoreCreatesBranchWorktreeAndRefreshesSnapshot() async throws {
    let repo = try await makeRepository()
    try write("root\n", to: repo.appending(path: "README.md"))
    try await commitAll(in: repo, message: "Initial")

    let store = await RepositoryStore()
    await store.openRepository(at: repo)

    let worktreeURL = temporaryDirectory()
    let worktreePath = canonicalPath(worktreeURL)
    await MainActor.run {
      store.presentCreateWorktree()
      store.createWorktreeDestinationPath = worktreeURL.path(percentEncoded: false)
      store.createWorktreeBranchName = "feature/store-worktree"
    }

    await store.createRequestedWorktree()

    let snapshot = await store.snapshot
    XCTAssertTrue(snapshot.worktrees.contains { canonicalPath($0.path) == worktreePath })
    let branch = try await client.git(["branch", "--show-current"], in: worktreeURL).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    XCTAssertEqual(branch, "feature/store-worktree")
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
      let previews = await client.conflictPreviews(entry, in: repository)
      XCTAssertEqual(previews.count, ConflictPreviewSide.allCases.count)
      XCTAssertTrue(previews.first { $0.side == .workingTree }?.text.contains("<<<<<<<") ?? false)
      XCTAssertEqual(previews.first { $0.side == .base }?.text, "base\nsecond\nthird\n")
      XCTAssertEqual(previews.first { $0.side == .ours }?.text, "main\n")
      XCTAssertEqual(previews.first { $0.side == .theirs }?.text, "side\n")

      try write("resolved\n", to: clone.appending(path: "story.txt"))
      let baseDiff = try await client.conflictResolvedDiff(
        entry,
        base: .base,
        algorithm: .histogram,
        whitespaceMode: .show,
        in: repository
      )
      let oursDiff = try await client.conflictResolvedDiff(
        entry,
        base: .ours,
        algorithm: .histogram,
        whitespaceMode: .show,
        in: repository
      )
      let theirsDiff = try await client.conflictResolvedDiff(
        entry,
        base: .theirs,
        algorithm: .histogram,
        whitespaceMode: .show,
        in: repository
      )
      XCTAssertTrue(baseDiff.contains("+resolved"))
      XCTAssertTrue(baseDiff.contains("-base"))
      XCTAssertTrue(oursDiff.contains("-main"))
      XCTAssertTrue(theirsDiff.contains("-side"))

      _ = try await client.resolveConflict(entry, choice: .markResolved, in: repository)
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
