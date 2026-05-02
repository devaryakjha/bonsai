import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class RepositoryStore {
  private let gitClient = GitClient()
  private let gitHubClient = GitHubClient()
  private let recentsKey = "bonsai.recentRepositories"
  private let recentCommitMessagesKey = "bonsai.recentCommitMessages"

  var selectedRepository: GitRepository?
  var recentRepositories: [GitRepository] = []
  var projectRepositories: [GitRepository] = []
  var projectWorkspaceGroups: [WorkspaceGroup] = []
  var snapshot = RepositorySnapshot()
  var selectedCommit: GitCommit?
  var selectedStash: GitStash?
  var selectedStatusEntry: GitStatusEntry?
  var selectedChangedFile: GitChangedFile?
  var selectedTreeEntry: GitTreeEntry?
  var mainMode: MainMode = .history {
    didSet {
      guard oldValue != mainMode else { return }
      alignSelectionForCurrentMode()
      Task { await refreshDiff() }
    }
  }
  var historySearchText = ""
  var diffText = ""
  var imageDiffSnapshot: ImageDiffSnapshot?
  var commitTreeEntries: [GitTreeEntry] = []
  var commitTreePath = ""
  var stashChangedFiles: [GitChangedFile] = []
  var treeBlobText = ""
  var commandResult: CommandResult?
  var gitHubNotifications: [GitHubNotification] = []
  var operationRequest: GitOperationRequest?
  var operationInput = ""
  var conflictResolutionRequest: ConflictResolutionRequest?
  var discardChangeRequest: DiscardChangeRequest?
  var interactiveRebasePlan: InteractiveRebasePlan?
  var resetRequest: ResetRequest?
  var reflogEntries: [GitReflogEntry] = []
  var reflogResetRequest: ReflogResetRequest?
  var remoteEditorRequest: RemoteEditorRequest?
  var gitHubRepositoryRequest: GitHubRepositoryRequest?
  var repositorySetupMode: RepositorySetupMode?
  var repositorySetupRemoteURL = ""
  var repositorySetupDestinationPath = ""
  var isRefreshing = false
  var errorMessage: String?
  var commitMessage = ""
  var recentCommitMessages: [String] = []
  var amendCommit = false
  var signCommit = false
  var diffAlgorithm: DiffAlgorithm = DiffAlgorithm(
    rawValue: UserDefaults.standard.string(forKey: "bonsai.diffAlgorithm") ?? ""
  ) ?? .histogram {
    didSet {
      UserDefaults.standard.set(diffAlgorithm.rawValue, forKey: "bonsai.diffAlgorithm")
      Task { await refreshDiff() }
    }
  }
  var diffDisplayMode: DiffDisplayMode = DiffDisplayMode(
    rawValue: UserDefaults.standard.string(forKey: "bonsai.diffDisplayMode") ?? ""
  ) ?? .unified {
    didSet {
      UserDefaults.standard.set(diffDisplayMode.rawValue, forKey: "bonsai.diffDisplayMode")
    }
  }

  var diffHunks: [DiffHunk] {
    GitParsers.parseDiffHunks(diffText)
  }

  var diffLineChanges: [DiffLineChange] {
    diffHunks.flatMap(GitParsers.parseDiffLineChanges)
  }

  var splitDiff: SplitDiff {
    GitParsers.parseSplitDiff(diffText)
  }

  var selectedPreviewPath: String? {
    selectedStatusEntry?.path ?? selectedChangedFile?.path ?? selectedTreeEntry?.path
  }

  var canRunSelectedFileLFSAction: Bool {
    snapshot.integrations.lfsAvailable && selectedPreviewPath != nil
  }

  var selectedPreviewIsImage: Bool {
    selectedPreviewPath.map(FilePreviewSupport.isImagePath) ?? false
  }

  var selectedDiffIsBinary: Bool {
    FilePreviewSupport.isBinaryDiff(diffText)
  }

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

  var filteredCommits: [GitCommit] {
    CommitFilter.filter(snapshot.commits, query: historySearchText)
  }

  var displayedChangedFiles: [GitChangedFile] {
    selectedStash == nil ? snapshot.changedFiles : stashChangedFiles
  }

  init() {
    recentRepositories = Self.loadRecents(key: recentsKey)
    recentCommitMessages = Self.loadStringList(key: recentCommitMessagesKey)
    refreshProjectRepositories()
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
    setSelectedRepository(repository)
    remember(repository)
    Task {
      await refreshAll()
    }
  }

  func rescanProjectsDirectory() {
    refreshProjectRepositories()
  }

  func openRepository(at url: URL) async {
    do {
      try await gitClient.validateRepository(at: url)
      let repository = GitRepository(path: url.path(percentEncoded: false))
      setSelectedRepository(repository)
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
      if let selectedStash,
         !snapshot.stashes.contains(where: { $0.id == selectedStash.id }) {
        self.selectedStash = nil
        stashChangedFiles = []
        selectedChangedFile = nil
      }
      if selectedStash != nil {
        selectedCommit = nil
      } else if selectedCommit == nil {
        selectedCommit = snapshot.commits.first
      } else if let current = selectedCommit,
                !snapshot.commits.contains(where: { $0.hash == current.hash }) {
        selectedCommit = snapshot.commits.first
      }
      if selectedChangedFile == nil && selectedStash == nil {
        selectedChangedFile = snapshot.changedFiles.first
      }
      if let selectedStash {
        stashChangedFiles = try await gitClient.changedFiles(in: repository, stash: selectedStash)
      }
      if mainMode == .history {
        try await refreshCommitTreeEntries(resetPath: commitTreeEntries.isEmpty)
      }
      await refreshDiff()
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func selectCommit(_ commit: GitCommit?) {
    selectedCommit = commit
    selectedStash = nil
    selectedChangedFile = nil
    selectedTreeEntry = nil
    stashChangedFiles = []
    commitTreePath = ""
    treeBlobText = ""
    Task {
      await refreshCommitFilesAndDiff()
    }
  }

  func selectChangedFile(_ file: GitChangedFile?) {
    selectedChangedFile = file
    selectedStatusEntry = nil
    selectedTreeEntry = nil
    treeBlobText = ""
    Task {
      await refreshDiff()
    }
  }

  func selectStash(_ stash: GitStash?) {
    selectedStash = stash
    selectedCommit = nil
    selectedChangedFile = nil
    selectedStatusEntry = nil
    selectedTreeEntry = nil
    commitTreeEntries = []
    commitTreePath = ""
    treeBlobText = ""

    Task {
      await refreshStashFilesAndDiff()
    }
  }

  func selectStatusEntry(_ entry: GitStatusEntry?) {
    selectedStatusEntry = entry
    selectedChangedFile = nil
    selectedStash = nil
    stashChangedFiles = []
    selectedTreeEntry = nil
    treeBlobText = ""
    Task {
      await refreshDiff()
    }
  }

  func openTreeEntry(_ entry: GitTreeEntry) {
    guard entry.isDirectory else {
      selectTreeBlob(entry)
      return
    }

    selectedTreeEntry = nil
    treeBlobText = ""
    commitTreePath = entry.path
    Task {
      await refreshCommitTree()
    }
  }

  func navigateTreeUp() {
    guard !commitTreePath.isEmpty else { return }
    selectedTreeEntry = nil
    treeBlobText = ""
    var components = commitTreePath.split(separator: "/").map(String.init)
    _ = components.popLast()
    commitTreePath = components.joined(separator: "/")
    Task {
      await refreshCommitTree()
    }
  }

  func selectTreeBlob(_ entry: GitTreeEntry) {
    selectedTreeEntry = entry
    selectedChangedFile = nil
    selectedStatusEntry = nil
    selectedStash = nil
    stashChangedFiles = []
    diffText = ""
    imageDiffSnapshot = nil

    Task {
      await refreshTreeBlob()
    }
  }

  func presentConflictResolver(for entry: GitStatusEntry) {
    selectedStatusEntry = entry
    selectedChangedFile = nil
    let preview = conflictPreview(for: entry)
    conflictResolutionRequest = ConflictResolutionRequest(entry: entry, preview: preview)
    Task {
      await refreshDiff()
    }
  }

  func resolveConflict(_ choice: ConflictResolutionChoice) async {
    guard let request = conflictResolutionRequest else { return }
    conflictResolutionRequest = nil
    await runMutation(title: "\(choice.rawValue) \(request.entry.path)") {
      try await gitClient.resolveConflict(request.entry, choice: choice, in: requiredRepository())
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

  func presentDiscardChange(_ entry: GitStatusEntry) {
    discardChangeRequest = DiscardChangeRequest(entry: entry)
  }

  func discardChange() async {
    guard let request = discardChangeRequest else { return }
    discardChangeRequest = nil
    await runMutation(title: "Discard \(request.entry.path)") {
      try await gitClient.discard(request.entry, in: requiredRepository())
    }
  }

  func stageHunk(_ hunk: DiffHunk) async {
    await runMutation(title: "Stage Hunk") {
      try await gitClient.stageHunk(hunk, in: requiredRepository())
    }
  }

  func unstageHunk(_ hunk: DiffHunk) async {
    await runMutation(title: "Unstage Hunk") {
      try await gitClient.unstageHunk(hunk, in: requiredRepository())
    }
  }

  func stageLineChange(_ change: DiffLineChange) async {
    await runMutation(title: "Stage \(change.title)") {
      try await gitClient.stageLineChange(change, in: requiredRepository())
    }
  }

  func unstageLineChange(_ change: DiffLineChange) async {
    await runMutation(title: "Unstage \(change.title)") {
      try await gitClient.unstageLineChange(change, in: requiredRepository())
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
    rememberCommitMessage(message)
  }

  func runRepositoryAction(_ action: RepositoryAction) async {
    await runMutation(title: action.rawValue) {
      try await gitClient.runAction(action, in: requiredRepository())
    }
  }

  func presentAddRemote() {
    remoteEditorRequest = RemoteEditorRequest(mode: .add, originalName: nil, name: "", url: "")
  }

  func presentEditRemote(_ remote: GitRemote) {
    remoteEditorRequest = RemoteEditorRequest(
      mode: .edit,
      originalName: remote.name,
      name: remote.name,
      url: remote.pushURL ?? remote.fetchURL ?? ""
    )
  }

  func saveRemote(name: String, url: String) async {
    guard let request = remoteEditorRequest else { return }
    remoteEditorRequest = nil
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty, !trimmedURL.isEmpty else {
      errorMessage = "Remote name and URL are required."
      return
    }

    await runMutation(title: request.mode.title) {
      switch request.mode {
      case .add:
        return try await gitClient.addRemote(name: trimmedName, url: trimmedURL, in: requiredRepository())
      case .edit:
        return try await gitClient.setRemoteURL(name: request.originalName ?? trimmedName, url: trimmedURL, in: requiredRepository())
      }
    }
  }

  func removeRemote(_ remote: GitRemote) async {
    await runMutation(title: "Remove Remote \(remote.name)") {
      try await gitClient.removeRemote(name: remote.name, in: requiredRepository())
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

  func presentCreateWorktree() {
    let defaultPath: String
    if let selectedRepository {
      let url = URL(filePath: selectedRepository.path, directoryHint: .isDirectory)
      defaultPath = url
        .deletingLastPathComponent()
        .appending(path: "\(url.lastPathComponent)-worktree", directoryHint: .isDirectory)
        .path(percentEncoded: false)
    } else {
      defaultPath = ""
    }

    operationInput = defaultPath
    operationRequest = GitOperationRequest(
      kind: .createWorktree,
      title: "Create Worktree",
      message: selectedCommit.map { "Create a worktree at \($0.shortHash)." } ?? "Create a worktree from HEAD.",
      placeholder: "~/projects/repository-worktree",
      defaultValue: defaultPath,
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

  func presentGitFlowStart(_ kind: GitFlowStartKind) {
    operationInput = ""
    let operationKind: GitOperationKind
    switch kind {
    case .feature:
      operationKind = .gitFlowFeatureStart
    case .release:
      operationKind = .gitFlowReleaseStart
    case .hotfix:
      operationKind = .gitFlowHotfixStart
    }
    operationRequest = GitOperationRequest(
      kind: operationKind,
      title: "Start Git-flow \(kind.title)",
      message: "Create a new \(kind.rawValue) branch using git-flow.",
      placeholder: kind == .release ? "0.1.0" : "name",
      defaultValue: "",
      primaryActionTitle: "Start"
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
    case .createWorktree:
      guard !value.isEmpty else { return }
      await runMutation(title: "Create Worktree") {
        try await gitClient.createWorktree(at: value, startPoint: selectedCommit?.hash ?? "HEAD", in: requiredRepository())
      }
    case .stashPush:
      await runMutation(title: "Create Stash") {
        try await gitClient.stashPush(message: value.isEmpty ? nil : value, in: requiredRepository())
      }
    case .gitFlowFeatureStart:
      guard !value.isEmpty else { return }
      await startGitFlow(kind: .feature, name: value)
    case .gitFlowReleaseStart:
      guard !value.isEmpty else { return }
      await startGitFlow(kind: .release, name: value)
    case .gitFlowHotfixStart:
      guard !value.isEmpty else { return }
      await startGitFlow(kind: .hotfix, name: value)
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

  func presentResetToSelectedCommit() {
    guard let selectedCommit else { return }
    resetRequest = ResetRequest(commit: selectedCommit)
  }

  func resetToSelectedCommit(mode: ResetMode) async {
    guard let request = resetRequest else { return }
    resetRequest = nil
    await runMutation(title: "Reset \(request.commit.shortHash)") {
      try await gitClient.reset(to: request.commit, mode: mode, in: requiredRepository())
    }
  }

  func resetToReflogEntry(mode: ResetMode) async {
    guard let request = reflogResetRequest else { return }
    reflogResetRequest = nil
    reflogEntries = []
    await runMutation(title: "Reset \(request.entry.shortHash)") {
      try await gitClient.reset(to: request.entry, mode: mode, in: requiredRepository())
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

  func removeWorktree(_ worktree: GitWorktree) async {
    await runMutation(title: "Remove Worktree \(worktree.name)") {
      try await gitClient.removeWorktree(worktree, in: requiredRepository())
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

  func updateSubmodule(_ submodule: GitSubmodule) async {
    await runMutation(title: "Update Submodule \(submodule.path)") {
      try await gitClient.updateSubmodule(submodule, in: requiredRepository())
    }
  }

  func openSubmodule(_ submodule: GitSubmodule) {
    guard let selectedRepository else { return }
    let url = URL(filePath: selectedRepository.path, directoryHint: .isDirectory)
      .appending(path: submodule.path, directoryHint: .isDirectory)
    Task {
      await openRepository(at: url)
    }
  }

  func lfsPull() async {
    await runMutation(title: "Git LFS Pull") {
      try await gitClient.lfsPull(in: requiredRepository())
    }
  }

  func lfsLockSelectedFile() async {
    guard let path = selectedPreviewPath else { return }
    await runMutation(title: "Git LFS Lock \(path)") {
      try await gitClient.lfsLock(path: path, in: requiredRepository())
    }
  }

  func lfsUnlockSelectedFile(force: Bool = false) async {
    guard let path = selectedPreviewPath else { return }
    await runMutation(title: "Git LFS Unlock \(path)") {
      try await gitClient.lfsUnlock(path: path, force: force, in: requiredRepository())
    }
  }

  func setCommitSigning(_ enabled: Bool) async {
    await runMutation(title: enabled ? "Enable GPG Signing" : "Disable GPG Signing") {
      try await gitClient.setCommitSigning(enabled, in: requiredRepository())
    }
  }

  func initializeGitFlow() async {
    await runMutation(title: "Initialize Git-flow") {
      try await gitClient.initializeGitFlow(in: requiredRepository())
    }
  }

  func startGitFlow(kind: GitFlowStartKind, name: String) async {
    await runMutation(title: "Start Git-flow \(kind.title)") {
      try await gitClient.startGitFlow(kind: kind, name: name, in: requiredRepository())
    }
  }

  func showReflog() async {
    do {
      reflogEntries = try await gitClient.reflogEntries(in: requiredRepository())
    } catch {
      commandResult = CommandResult(title: "Reflog", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func checkoutReflogEntry(_ entry: GitReflogEntry) async {
    reflogEntries = []
    await runMutation(title: "Checkout \(entry.shortHash)") {
      try await gitClient.checkout(entry.hash, in: requiredRepository())
    }
  }

  func presentResetToReflogEntry(_ entry: GitReflogEntry) {
    reflogEntries = []
    reflogResetRequest = ReflogResetRequest(entry: entry)
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

  func fetchGitHubNotifications() async {
    guard let token = githubToken() else { return }

    do {
      gitHubNotifications = try await gitHubClient.notifications(token: token)
      let summary = gitHubNotifications.prefix(8)
        .map { "\($0.repository.fullName): \($0.subject.title)" }
        .joined(separator: "\n")
      commandResult = CommandResult(
        title: "GitHub Notifications",
        output: summary.isEmpty ? "No unread notifications." : summary,
        isError: false
      )
    } catch {
      commandResult = CommandResult(title: "GitHub Notifications", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func markGitHubNotificationsRead() async {
    guard let token = githubToken() else { return }

    do {
      try await gitHubClient.markNotificationsRead(token: token)
      gitHubNotifications = []
      commandResult = CommandResult(title: "GitHub Notifications", output: "Marked notifications as read.", isError: false)
    } catch {
      commandResult = CommandResult(title: "GitHub Notifications", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func presentCreateGitHubRepository() {
    gitHubRepositoryRequest = GitHubRepositoryRequest(
      operation: .create,
      owner: "",
      name: selectedRepository?.name ?? "",
      repositoryDescription: "",
      isPrivate: false
    )
  }

  func presentDeleteGitHubRepository() {
    gitHubRepositoryRequest = GitHubRepositoryRequest(
      operation: .delete,
      owner: "",
      name: selectedRepository?.name ?? "",
      repositoryDescription: "",
      isPrivate: false
    )
  }

  func runGitHubRepositoryOperation(_ request: GitHubRepositoryRequest) async {
    guard let token = githubToken() else { return }
    gitHubRepositoryRequest = nil

    do {
      switch request.operation {
      case .create:
        let repository = try await gitHubClient.createRepository(
          token: token,
          name: request.name.trimmingCharacters(in: .whitespacesAndNewlines),
          description: request.repositoryDescription.trimmingCharacters(in: .whitespacesAndNewlines),
          isPrivate: request.isPrivate
        )
        commandResult = CommandResult(
          title: request.operation.title,
          output: [repository.fullName, repository.cloneURL, repository.sshURL, repository.htmlURL]
            .compactMap { $0 }
            .joined(separator: "\n"),
          isError: false
        )
      case .delete:
        try await gitHubClient.deleteRepository(
          token: token,
          owner: request.owner.trimmingCharacters(in: .whitespacesAndNewlines),
          name: request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        commandResult = CommandResult(title: request.operation.title, output: "Deleted \(request.owner)/\(request.name).", isError: false)
      }
    } catch {
      commandResult = CommandResult(title: request.operation.title, output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func presentInteractiveRebase() async {
    do {
      interactiveRebasePlan = try await gitClient.interactiveRebasePlan(in: requiredRepository())
    } catch {
      commandResult = CommandResult(title: "Interactive Rebase", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func setRebaseAction(_ action: RebaseTodoAction, for item: InteractiveRebaseItem) {
    guard let index = interactiveRebasePlan?.items.firstIndex(where: { $0.id == item.id }) else { return }
    interactiveRebasePlan?.items[index].action = action
  }

  func moveRebaseItem(_ item: InteractiveRebaseItem, direction: Int) {
    guard var plan = interactiveRebasePlan,
          let index = plan.items.firstIndex(where: { $0.id == item.id }) else { return }
    let target = index + direction
    guard plan.items.indices.contains(target) else { return }
    plan.items.swapAt(index, target)
    interactiveRebasePlan = plan
  }

  func startInteractiveRebase() async {
    guard let plan = interactiveRebasePlan else { return }
    interactiveRebasePlan = nil
    await runMutation(title: "Interactive Rebase") {
      try await gitClient.startInteractiveRebase(plan, in: requiredRepository())
    }
  }

  private func refreshCommitFilesAndDiff() async {
    guard let repository = selectedRepository else { return }
    do {
      snapshot.changedFiles = try await gitClient.changedFiles(in: repository, commit: selectedCommit)
      try await refreshCommitTreeEntries(resetPath: true)
      selectedChangedFile = snapshot.changedFiles.first
      await refreshDiff()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func refreshStashFilesAndDiff() async {
    guard let repository = selectedRepository else { return }
    do {
      stashChangedFiles = try await gitClient.changedFiles(in: repository, stash: selectedStash)
      selectedChangedFile = stashChangedFiles.first
      await refreshDiff()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func refreshCommitTree() async {
    do {
      try await refreshCommitTreeEntries(resetPath: false)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func refreshCommitTreeEntries(resetPath: Bool) async throws {
    guard let repository = selectedRepository else {
      commitTreeEntries = []
      commitTreePath = ""
      return
    }
    if resetPath {
      commitTreePath = ""
      selectedTreeEntry = nil
      treeBlobText = ""
    }
    commitTreeEntries = try await gitClient.treeEntries(in: repository, commit: selectedCommit, path: commitTreePath)
  }

  private func refreshTreeBlob() async {
    guard let repository = selectedRepository,
          let selectedCommit,
          let selectedTreeEntry else {
      treeBlobText = ""
      return
    }

    do {
      treeBlobText = try await gitClient.blobText(path: selectedTreeEntry.path, commit: selectedCommit, in: repository)
      errorMessage = nil
    } catch {
      treeBlobText = ""
      errorMessage = error.localizedDescription
    }
  }

  private func alignSelectionForCurrentMode() {
    switch mainMode {
    case .history:
      selectedStatusEntry = nil
      if selectedCommit == nil {
        selectedCommit = snapshot.commits.first
      }
      if selectedChangedFile == nil {
        selectedChangedFile = snapshot.changedFiles.first
      }
    case .changes:
      selectedChangedFile = nil
      if selectedStatusEntry == nil {
        selectedStatusEntry = snapshot.status.first
      }
    }
  }

  private func refreshDiff() async {
    imageDiffSnapshot = nil

    guard let repository = selectedRepository else {
      diffText = ""
      return
    }

    do {
      if let entry = selectedStatusEntry {
        diffText = try await gitClient.diffForWorkingTreeFile(entry, staged: entry.isStaged, algorithm: diffAlgorithm, in: repository)
        if FilePreviewSupport.isImagePath(entry.path) {
          imageDiffSnapshot = await gitClient.imageDiffForWorkingTreeFile(entry, in: repository)
        }
      } else if let stash = selectedStash, let file = selectedChangedFile {
        diffText = try await gitClient.diffForStashFile(file, stash: stash, algorithm: diffAlgorithm, in: repository)
      } else if let file = selectedChangedFile, let commit = selectedCommit {
        diffText = try await gitClient.diffForCommitFile(file, commit: commit, algorithm: diffAlgorithm, in: repository)
        if FilePreviewSupport.isImagePath(file.path) {
          imageDiffSnapshot = await gitClient.imageDiffForCommitFile(file, commit: commit, in: repository)
        }
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

  private func conflictPreview(for entry: GitStatusEntry) -> String {
    guard let selectedRepository else { return "" }
    let fileURL = URL(filePath: selectedRepository.path, directoryHint: .isDirectory).appending(path: entry.path)
    guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
      return "Bonsai could not preview this file as UTF-8 text."
    }
    let limit = 80_000
    if content.count > limit {
      return String(content.prefix(limit)) + "\n\n[Preview truncated]"
    }
    return content
  }

  private func remember(_ repository: GitRepository) {
    recentRepositories.removeAll { $0.path == repository.path }
    recentRepositories.insert(repository, at: 0)
    recentRepositories = Array(recentRepositories.prefix(20))
    saveRecents()
  }

  private func refreshProjectRepositories() {
    projectRepositories = ProjectRepositoryScanner.scanDefaultProjectsDirectory()
    projectWorkspaceGroups = ProjectRepositoryScanner.scanDefaultWorkspaceGroups()
  }

  private func githubToken() -> String? {
    let token = UserDefaults.standard.string(forKey: "bonsai.githubToken")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !token.isEmpty else {
      errorMessage = "Add a GitHub personal access token in Settings first."
      return nil
    }
    return token
  }

  private func setSelectedRepository(_ repository: GitRepository) {
    selectedRepository = repository
    snapshot = RepositorySnapshot()
    selectedCommit = nil
    selectedStatusEntry = nil
    selectedChangedFile = nil
    selectedStash = nil
    stashChangedFiles = []
    diffText = ""
    commandResult = nil
  }

  private func saveRecents() {
    if let data = try? JSONEncoder().encode(recentRepositories) {
      UserDefaults.standard.set(data, forKey: recentsKey)
    }
  }

  private func rememberCommitMessage(_ message: String) {
    recentCommitMessages.removeAll { $0 == message }
    recentCommitMessages.insert(message, at: 0)
    recentCommitMessages = Array(recentCommitMessages.prefix(20))
    if let data = try? JSONEncoder().encode(recentCommitMessages) {
      UserDefaults.standard.set(data, forKey: recentCommitMessagesKey)
    }
  }

  private static func loadRecents(key: String) -> [GitRepository] {
    guard let data = UserDefaults.standard.data(forKey: key),
          let repositories = try? JSONDecoder().decode([GitRepository].self, from: data) else {
      return []
    }
    return repositories
  }

  private static func loadStringList(key: String) -> [String] {
    guard let data = UserDefaults.standard.data(forKey: key),
          let values = try? JSONDecoder().decode([String].self, from: data) else {
      return []
    }
    return values
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
