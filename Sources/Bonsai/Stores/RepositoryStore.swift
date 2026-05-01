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
  var projectRepositories: [GitRepository] = []
  var snapshot = RepositorySnapshot()
  var selectedCommit: GitCommit?
  var selectedStatusEntry: GitStatusEntry?
  var selectedChangedFile: GitChangedFile?
  var mainMode: MainMode = .history
  var diffText = ""
  var commandResult: CommandResult?
  var operationRequest: GitOperationRequest?
  var operationInput = ""
  var repositorySetupMode: RepositorySetupMode?
  var repositorySetupRemoteURL = ""
  var repositorySetupDestinationPath = ""
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
    projectRepositories = ProjectRepositoryScanner.scanDefaultProjectsDirectory()
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

  func presentCloneRepository() {
    repositorySetupRemoteURL = ""
    repositorySetupDestinationPath = Self.defaultProjectsDirectory()
      .appending(path: "Repository", directoryHint: .isDirectory)
      .path(percentEncoded: false)
    repositorySetupMode = .clone
  }

  func presentCreateRepository() {
    repositorySetupRemoteURL = ""
    repositorySetupDestinationPath = Self.defaultProjectsDirectory()
      .appending(path: "NewRepository", directoryHint: .isDirectory)
      .path(percentEncoded: false)
    repositorySetupMode = .create
  }

  func chooseRepositorySetupDestination() {
    let panel = NSOpenPanel()
    panel.title = repositorySetupMode == .clone ? "Choose Clone Parent Folder" : "Choose Repository Folder"
    panel.prompt = "Choose"
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false

    guard panel.runModal() == .OK, let url = panel.url else { return }
    if repositorySetupMode == .clone, !repositorySetupRemoteURL.isEmpty {
      repositorySetupDestinationPath = url
        .appending(path: Self.repositoryName(fromRemoteURL: repositorySetupRemoteURL), directoryHint: .isDirectory)
        .path(percentEncoded: false)
    } else {
      repositorySetupDestinationPath = url.path(percentEncoded: false)
    }
  }

  func updateCloneDestinationFromRemote() {
    guard repositorySetupMode == .clone else { return }
    let parent = URL(filePath: repositorySetupDestinationPath, directoryHint: .isDirectory).deletingLastPathComponent()
    let repositoryName = Self.repositoryName(fromRemoteURL: repositorySetupRemoteURL)
    guard !repositoryName.isEmpty else { return }
    repositorySetupDestinationPath = parent
      .appending(path: repositoryName, directoryHint: .isDirectory)
      .path(percentEncoded: false)
  }

  func confirmRepositorySetup() async {
    guard let mode = repositorySetupMode else { return }
    let destination = URL(filePath: repositorySetupDestinationPath, directoryHint: .isDirectory)
    repositorySetupMode = nil

    do {
      let output: String
      switch mode {
      case .clone:
        let remote = repositorySetupRemoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !remote.isEmpty else {
          errorMessage = "Remote URL is required."
          return
        }
        output = try await gitClient.cloneRepository(from: remote, to: destination)
      case .create:
        output = try await gitClient.initializeRepository(at: destination)
      }

      commandResult = CommandResult(title: mode.title, output: output.isEmpty ? "Completed." : output, isError: false)
      await openRepository(at: destination)
      rescanProjectsDirectory()
    } catch {
      commandResult = CommandResult(title: mode.title, output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func openRecent(_ repository: GitRepository) {
    selectedRepository = repository
    remember(repository)
    Task {
      await refreshAll()
    }
  }

  func rescanProjectsDirectory() {
    projectRepositories = ProjectRepositoryScanner.scanDefaultProjectsDirectory()
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

  func presentCreateBranch() {
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .createBranch,
      title: "Create Branch",
      message: selectedCommit.map { "Create a branch at \($0.shortHash)." } ?? "Create a branch at HEAD.",
      placeholder: "feature/new-work",
      defaultValue: "",
      primaryActionTitle: "Create"
    )
  }

  func presentCreateTag() {
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .createTag,
      title: "Create Tag",
      message: selectedCommit.map { "Create a tag at \($0.shortHash)." } ?? "Create a tag at HEAD.",
      placeholder: "v0.1.0",
      defaultValue: "",
      primaryActionTitle: "Create"
    )
  }

  func presentStashPush() {
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .stashPush,
      title: "Create Stash",
      message: "Save current working tree changes to a stash.",
      placeholder: "Optional stash message",
      defaultValue: "",
      primaryActionTitle: "Stash"
    )
  }

  func confirmOperation() async {
    guard let request = operationRequest else { return }
    let value = operationInput.trimmingCharacters(in: .whitespacesAndNewlines)
    operationRequest = nil

    switch request.kind {
    case .createBranch:
      guard !value.isEmpty else { return }
      await runMutation(title: "Create Branch \(value)") {
        try await gitClient.createBranch(named: value, startPoint: selectedCommit?.hash, in: requiredRepository())
      }
    case .createTag:
      guard !value.isEmpty else { return }
      await runMutation(title: "Create Tag \(value)") {
        try await gitClient.createTag(named: value, target: selectedCommit?.hash, in: requiredRepository())
      }
    case .stashPush:
      await runMutation(title: "Create Stash") {
        try await gitClient.stashPush(message: value.isEmpty ? nil : value, in: requiredRepository())
      }
    }
  }

  func checkout(_ ref: GitRef) async {
    await runMutation(title: "Checkout \(ref.shortName)") {
      try await gitClient.checkout(ref.shortName, in: requiredRepository())
    }
  }

  func checkoutSelectedCommit() async {
    guard let selectedCommit else { return }
    await runMutation(title: "Checkout \(selectedCommit.shortHash)") {
      try await gitClient.checkout(selectedCommit.hash, in: requiredRepository())
    }
  }

  func delete(_ ref: GitRef) async {
    await runMutation(title: "Delete \(ref.shortName)") {
      switch ref.kind {
      case .localBranch:
        return try await gitClient.deleteBranch(ref.shortName, force: false, in: requiredRepository())
      case .remoteBranch:
        let parts = ref.shortName.split(separator: "/", maxSplits: 1).map(String.init)
        let remote = parts.first ?? "origin"
        let branch = parts.count > 1 ? parts[1] : ref.shortName
        return try await gitClient.runRaw(["push", remote, "--delete", branch], in: requiredRepository())
      case .tag:
        return try await gitClient.deleteTag(ref.shortName, in: requiredRepository())
      }
    }
  }

  func runRevisionCommand(_ command: String) async {
    guard let selectedCommit else { return }
    await runMutation(title: "\(command.capitalized) \(selectedCommit.shortHash)") {
      try await gitClient.runRaw([command, selectedCommit.hash], in: requiredRepository())
    }
  }

  func applyStash(_ stash: GitStash, pop: Bool) async {
    await runMutation(title: pop ? "Pop \(stash.index)" : "Apply \(stash.index)") {
      try await gitClient.stashApply(stash, pop: pop, in: requiredRepository())
    }
  }

  func dropStash(_ stash: GitStash) async {
    await runMutation(title: "Drop \(stash.index)") {
      try await gitClient.stashDrop(stash, in: requiredRepository())
    }
  }

  func updateSubmodules() async {
    await runMutation(title: "Update Submodules") {
      try await gitClient.updateSubmodules(in: requiredRepository())
    }
  }

  func showReflog() async {
    await runReadOnlyCommand(title: "Reflog") {
      try await gitClient.reflog(in: requiredRepository())
    }
  }

  func showBlameForSelection() async {
    guard let path = selectedChangedFile?.path ?? selectedStatusEntry?.path else { return }
    await runReadOnlyCommand(title: "Blame \(path)") {
      try await gitClient.blame(path: path, in: requiredRepository())
    }
  }

  func showFileHistoryForSelection() async {
    guard let path = selectedChangedFile?.path ?? selectedStatusEntry?.path else { return }
    await runReadOnlyCommand(title: "File History \(path)") {
      try await gitClient.fileHistory(path: path, in: requiredRepository())
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

  private func runReadOnlyCommand(title: String, operation: () async throws -> String) async {
    do {
      let output = try await operation()
      commandResult = CommandResult(title: title, output: output.isEmpty ? "No output." : output, isError: false)
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

  static func defaultProjectsDirectory() -> URL {
    URL(filePath: NSHomeDirectory()).appending(path: "projects", directoryHint: .isDirectory)
  }

  static func repositoryName(fromRemoteURL remoteURL: String) -> String {
    let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "Repository" }
    let withoutTrailingSlash = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let lastComponent: String
    if let url = URL(string: withoutTrailingSlash), let component = url.pathComponents.last, component != "/" {
      lastComponent = component
    } else {
      lastComponent = withoutTrailingSlash
        .split(separator: "/")
        .last
        .map(String.init) ?? withoutTrailingSlash
    }
    let withoutGit = lastComponent.hasSuffix(".git") ? String(lastComponent.dropLast(4)) : lastComponent
    return withoutGit.isEmpty ? "Repository" : withoutGit
  }
}

enum RepositoryStoreError: LocalizedError {
  case noRepository

  var errorDescription: String? {
    "No repository is selected."
  }
}
