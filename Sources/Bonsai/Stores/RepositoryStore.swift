import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class RepositoryStore {
  private let gitClient = GitClient()
  private let recentsKey = "bonsai.recentRepositories"

  var selectedRepository: GitRepository?
  var recentRepositories: [GitRepository] = []
  var snapshot = RepositorySnapshot()
  var selectedCommit: GitCommit?
  var selectedStatusEntry: GitStatusEntry?
  var selectedChangedFile: GitChangedFile?
  var mainMode: MainMode = .history
  var diffText = ""
  var commandResult: CommandResult?
  var isRefreshing = false
  var errorMessage: String?
  var commitMessage = ""
  var amendCommit = false
  var signCommit = false

  var stagedChanges: [GitStatusEntry] {
    snapshot.status.filter(\.isStaged)
  }

  var unstagedChanges: [GitStatusEntry] {
    snapshot.status.filter { !$0.isStaged && !$0.isConflicted }
  }

  var conflictedChanges: [GitStatusEntry] {
    snapshot.status.filter(\.isConflicted)
  }

  var localBranches: [GitRef] {
    snapshot.refs.filter { $0.kind == .localBranch }
  }

  var remoteBranches: [GitRef] {
    snapshot.refs.filter { $0.kind == .remoteBranch }
  }

  var tags: [GitRef] {
    snapshot.refs.filter { $0.kind == .tag }
  }

  init() {
    recentRepositories = Self.loadRecents(key: recentsKey)
    selectedRepository = recentRepositories.first
  }

  func presentOpenRepositoryPanel() {
    let panel = NSOpenPanel()
    panel.title = "Open Git Repository"
    panel.prompt = "Open"
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false

    guard panel.runModal() == .OK, let url = panel.url else { return }
    Task {
      await openRepository(at: url)
    }
  }

  func openRecent(_ repository: GitRepository) {
    selectedRepository = repository
    remember(repository)
    Task {
      await refreshAll()
    }
  }

  func openRepository(at url: URL) async {
    do {
      try await gitClient.validateRepository(at: url)
      let repository = GitRepository(path: url.path(percentEncoded: false))
      selectedRepository = repository
      remember(repository)
      await refreshAll()
    } catch {
      errorMessage = "That folder is not a Git repository.\n\(error.localizedDescription)"
    }
  }

  func refreshAll() async {
    guard let repository = selectedRepository else { return }
    isRefreshing = true
    defer { isRefreshing = false }

    do {
      snapshot = try await gitClient.snapshot(for: repository, selectedCommit: selectedCommit)
      if selectedCommit == nil {
        selectedCommit = snapshot.commits.first
      } else if let current = selectedCommit,
                !snapshot.commits.contains(where: { $0.hash == current.hash }) {
        selectedCommit = snapshot.commits.first
      }
      if selectedChangedFile == nil {
        selectedChangedFile = snapshot.changedFiles.first
      }
      await refreshDiff()
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func selectCommit(_ commit: GitCommit?) {
    selectedCommit = commit
    selectedChangedFile = nil
    Task {
      await refreshCommitFilesAndDiff()
    }
  }

  func selectChangedFile(_ file: GitChangedFile?) {
    selectedChangedFile = file
    selectedStatusEntry = nil
    Task {
      await refreshDiff()
    }
  }

  func selectStatusEntry(_ entry: GitStatusEntry?) {
    selectedStatusEntry = entry
    selectedChangedFile = nil
    Task {
      await refreshDiff()
    }
  }

  func stage(_ entry: GitStatusEntry) async {
    await runMutation(title: "Stage \(entry.path)") {
      try await gitClient.stage(entry, in: requiredRepository())
    }
  }

  func unstage(_ entry: GitStatusEntry) async {
    await runMutation(title: "Unstage \(entry.path)") {
      try await gitClient.unstage(entry, in: requiredRepository())
    }
  }

  func commit() async {
    let message = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !message.isEmpty else {
      errorMessage = "Commit message is required."
      return
    }

    await runMutation(title: amendCommit ? "Amend Commit" : "Commit") {
      try await gitClient.commit(message: message, amend: amendCommit, sign: signCommit, in: requiredRepository())
    }
    commitMessage = ""
    amendCommit = false
  }

  func runRepositoryAction(_ action: RepositoryAction) async {
    await runMutation(title: action.rawValue) {
      try await gitClient.runAction(action, in: requiredRepository())
    }
  }

  private func refreshCommitFilesAndDiff() async {
    guard let repository = selectedRepository else { return }
    do {
      snapshot.changedFiles = try await gitClient.changedFiles(in: repository, commit: selectedCommit)
      selectedChangedFile = snapshot.changedFiles.first
      await refreshDiff()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func refreshDiff() async {
    guard let repository = selectedRepository else {
      diffText = ""
      return
    }

    do {
      if let entry = selectedStatusEntry {
        diffText = try await gitClient.diffForWorkingTreeFile(entry, staged: entry.isStaged, in: repository)
      } else if let file = selectedChangedFile, let commit = selectedCommit {
        diffText = try await gitClient.diffForCommitFile(file, commit: commit, in: repository)
      } else {
        diffText = ""
      }
    } catch {
      diffText = ""
      errorMessage = error.localizedDescription
    }
  }

  private func runMutation(title: String, operation: () async throws -> String) async {
    do {
      let output = try await operation()
      commandResult = CommandResult(title: title, output: output.isEmpty ? "Completed." : output, isError: false)
      await refreshAll()
    } catch {
      commandResult = CommandResult(title: title, output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  private func requiredRepository() throws -> GitRepository {
    guard let selectedRepository else {
      throw RepositoryStoreError.noRepository
    }
    return selectedRepository
  }

  private func remember(_ repository: GitRepository) {
    recentRepositories.removeAll { $0.path == repository.path }
    recentRepositories.insert(repository, at: 0)
    recentRepositories = Array(recentRepositories.prefix(20))
    saveRecents()
  }

  private func saveRecents() {
    if let data = try? JSONEncoder().encode(recentRepositories) {
      UserDefaults.standard.set(data, forKey: recentsKey)
    }
  }

  private static func loadRecents(key: String) -> [GitRepository] {
    guard let data = UserDefaults.standard.data(forKey: key),
          let repositories = try? JSONDecoder().decode([GitRepository].self, from: data) else {
      return []
    }
    return repositories
  }
}

enum RepositoryStoreError: LocalizedError {
  case noRepository

  var errorDescription: String? {
    "No repository is selected."
  }
}
