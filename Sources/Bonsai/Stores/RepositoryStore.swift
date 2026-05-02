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
  private let autoRefreshKey = "bonsai.autoRefresh"

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
  var blameDocument: GitBlameDocument?
  var fileHistoryDocument: GitFileHistoryDocument?
  var lineHistoryDocument: GitLineHistoryDocument?
  var gitHubNotifications: [GitHubNotification] = []
  var operationRequest: GitOperationRequest?
  var operationInput = ""
  var branchRenameSource: GitRef?
  var branchStartPoint: String?
  var tagRenameSource: GitRef?
  var tagTarget: String?
  var stashBranchSource: GitStash?
  var conflictResolutionRequest: ConflictResolutionRequest?
  var discardChangeRequest: DiscardChangeRequest?
  var discardPatchRequest: DiscardPatchRequest?
  var dropStashRequest: DropStashRequest?
  var interactiveRebasePlan: InteractiveRebasePlan?
  var revisionCommandRequest: RevisionCommandRequest?
  var resetRequest: ResetRequest?
  var deleteRefRequest: DeleteRefRequest?
  var deleteRefForce = false
  var reflogEntries: [GitReflogEntry] = []
  var reflogResetRequest: ReflogResetRequest?
  var remoteEditorRequest: RemoteEditorRequest?
  var removeRemoteRequest: RemoveRemoteRequest?
  var removeWorktreeRequest: RemoveWorktreeRequest?
  var createWorktreeRequest: CreateWorktreeRequest?
  var createWorktreeDestinationPath = ""
  var createWorktreeBranchName = ""
  var removeWorktreeForce = false
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

  var canCopyCurrentPatch: Bool {
    !diffText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var canOpenSelectedFile: Bool {
    selectedRepository != nil && selectedPreviewPath != nil
  }

  var canCopySelectedFileAbsolutePath: Bool {
    selectedRepository != nil && selectedPreviewPath != nil
  }

  func copySelectedFileAbsolutePath() {
    guard let path = selectedPreviewPath else { return }
    copyAbsoluteFilePath(path: path)
  }

  func copyAbsoluteFilePath(path: String) {
    guard let selectedRepository else { return }
    PasteboardWriter.copy(RepositoryFileLocator.filePath(repository: selectedRepository, path: path))
  }

  func openSelectedFile() {
    guard let path = selectedPreviewPath else { return }
    openFile(path: path)
  }

  func openFile(path: String) {
    guard let selectedRepository else { return }
    if !FileOpenLauncher.openFile(repository: selectedRepository, path: path) {
      let url = FileOpenLauncher.targetURL(repository: selectedRepository, path: path)
      let output = "Could not open \(url.path(percentEncoded: false))."
      errorMessage = output
      commandResult = CommandResult(title: "Open File", output: output, isError: true)
    }
  }

  func revealInFinder(path: String) {
    guard let selectedRepository else { return }
    NSWorkspace.shared.activateFileViewerSelecting([
      RepositoryFileLocator.fileURL(repository: selectedRepository, path: path)
    ])
  }

  func revealRepositoryInFinder() {
    guard let selectedRepository else { return }
    revealRepositoryInFinder(selectedRepository)
  }

  func revealRepositoryInFinder(_ repository: GitRepository) {
    NSWorkspace.shared.activateFileViewerSelecting([
      RepositoryFileLocator.repositoryURL(repository)
    ])
  }

  func openRepositoryInTerminal() {
    guard let selectedRepository else { return }
    openRepositoryInTerminal(selectedRepository)
  }

  func openRepositoryInTerminal(_ repository: GitRepository) {
    openDirectoryInTerminal(RepositoryFileLocator.repositoryURL(repository))
  }

  func copyRepositoryPath() {
    guard let selectedRepository else { return }
    copyRepositoryPath(selectedRepository)
  }

  func copyRepositoryPath(_ repository: GitRepository) {
    PasteboardWriter.copy(repository.path)
  }

  func revealWorkspaceGroupInFinder(_ group: WorkspaceGroup) {
    NSWorkspace.shared.activateFileViewerSelecting([
      URL(filePath: group.path)
    ])
  }

  func openWorkspaceGroupInTerminal(_ group: WorkspaceGroup) {
    openDirectoryInTerminal(URL(filePath: group.path, directoryHint: .isDirectory))
  }

  func copyWorkspaceGroupPath(_ group: WorkspaceGroup) {
    PasteboardWriter.copy(group.path)
  }

  func revealWorktreeInFinder(_ worktree: GitWorktree) {
    NSWorkspace.shared.activateFileViewerSelecting([
      worktree.directoryURL
    ])
  }

  func openWorktreeInTerminal(_ worktree: GitWorktree) {
    openDirectoryInTerminal(worktree.directoryURL)
  }

  private func openDirectoryInTerminal(_ directoryURL: URL) {
    do {
      try TerminalLauncher.openDirectory(directoryURL)
    } catch {
      let output = "Could not open Terminal for \(directoryURL.path(percentEncoded: false))."
      errorMessage = output
      commandResult = CommandResult(title: "Open in Terminal", output: output, isError: true)
    }
  }

  var commitReadinessIssue: String? {
    if commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "Commit message is required."
    }
    if !amendCommit && stagedChanges.isEmpty {
      return "Stage changes before committing."
    }
    return nil
  }

  var canCommit: Bool {
    commitReadinessIssue == nil
  }

  var commitOptionsSummary: String {
    let signingEnabled = signCommit || snapshot.integrations.gpgSigningEnabled
    switch (amendCommit, signingEnabled) {
    case (true, true):
      return "Amend, signing on"
    case (true, false):
      return "Amend"
    case (false, true):
      return "Signing on"
    case (false, false):
      return ""
    }
  }

  var canStageSelectedStatusEntry: Bool {
    guard let selectedStatusEntry else { return false }
    return !selectedStatusEntry.isStaged && !selectedStatusEntry.isConflicted
  }

  var canUnstageSelectedStatusEntry: Bool {
    selectedStatusEntry?.isStaged == true
  }

  var canIgnoreSelectedStatusEntry: Bool {
    selectedStatusEntry?.isUntracked == true
  }

  var canIgnoreSelectedStatusEntryExtension: Bool {
    guard selectedStatusEntry?.isUntracked == true,
          let path = selectedStatusEntry?.path else { return false }
    return GitIgnorePattern.extensionPattern(for: path) != nil
  }

  var canIgnoreSelectedStatusEntryDirectory: Bool {
    guard selectedStatusEntry?.isUntracked == true,
          let path = selectedStatusEntry?.path else { return false }
    return GitIgnorePattern.directoryPattern(for: path) != nil
  }

  var canStageAll: Bool {
    !unstagedChanges.isEmpty
  }

  var canUnstageAll: Bool {
    !stagedChanges.isEmpty
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

  var currentBranch: GitRef? {
    localBranches.first(where: \.isHead)
  }

  var pullReadinessIssue: String? {
    guard let currentBranch else {
      return selectedRepository == nil ? nil : "Checkout a branch before pulling."
    }
    if currentBranch.upstream == nil {
      return "Set an upstream before pulling."
    }
    if currentBranch.upstreamGone {
      return "Upstream branch is gone."
    }
    return nil
  }

  var canPull: Bool {
    pullReadinessIssue == nil
  }

  var publishRemote: GitRemote? {
    snapshot.remotes.first(where: { $0.name == "origin" }) ?? snapshot.remotes.first
  }

  var shouldPublishCurrentBranch: Bool {
    currentBranch?.upstream == nil && publishRemote != nil
  }

  var pushReadinessIssue: String? {
    guard let currentBranch else {
      return selectedRepository == nil ? nil : "Checkout a branch before pushing."
    }
    if currentBranch.upstream == nil && publishRemote == nil {
      return "Add a remote before publishing."
    }
    return nil
  }

  var canPush: Bool {
    pushReadinessIssue == nil
  }

  var pushActionTitle: String {
    shouldPublishCurrentBranch ? "Publish" : (currentBranch?.pushTitle ?? "Push")
  }

  var remoteBranches: [GitRef] {
    snapshot.refs.filter { $0.kind == .remoteBranch }
  }

  var tags: [GitRef] {
    snapshot.refs.filter { $0.kind == .tag }
  }

  var tagPushRemotes: [GitRemote] {
    snapshot.remotes.filter { $0.fetchURL != nil || $0.pushURL != nil }
  }

  var branchPushRemotes: [GitRemote] {
    tagPushRemotes
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
      repositorySetupDestinationPath = Self.cloneDestination(parentDirectory: url, remoteURL: repositorySetupRemoteURL)
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
    repositorySetupDestinationPath = Self.cloneDestination(parentDirectory: parent, remoteURL: repositorySetupRemoteURL)
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

      await openRepository(at: destination)
      commandResult = CommandResult(title: mode.title, output: output.isEmpty ? "Completed." : output, isError: false)
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

  func removeRecentRepository(_ repository: GitRepository) {
    recentRepositories.removeAll { $0.path == repository.path }
    saveRecents()
  }

  func clearRecentRepositories() {
    recentRepositories.removeAll()
    saveRecents()
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
      reconcileSelectedStatusEntry()
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

  func focusCommit(hash: String) async {
    guard let repository = selectedRepository else { return }

    do {
      let commit: GitCommit
      if let existing = snapshot.commits.first(where: { $0.hash == hash || $0.shortHash == hash }) {
        commit = existing
      } else {
        commit = try await gitClient.commit(revision: hash, in: repository)
        snapshot.commits.insert(commit, at: 0)
      }

      selectedCommit = commit
      selectedStash = nil
      selectedChangedFile = nil
      selectedStatusEntry = nil
      selectedTreeEntry = nil
      stashChangedFiles = []
      commitTreePath = ""
      treeBlobText = ""
      blameDocument = nil
      fileHistoryDocument = nil
      lineHistoryDocument = nil
      mainMode = .history
      await refreshCommitFilesAndDiff()
      errorMessage = nil
    } catch {
      commandResult = CommandResult(title: "Show commit", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
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

  func stageSelectedStatusEntry() async {
    guard canStageSelectedStatusEntry, let selectedStatusEntry else { return }
    await stage(selectedStatusEntry)
  }

  func stageAll() async {
    let entries = unstagedChanges
    guard !entries.isEmpty else { return }
    await runMutation(title: "Stage all") {
      try await gitClient.stageAll(entries, in: requiredRepository())
    }
  }

  func unstage(_ entry: GitStatusEntry) async {
    await runMutation(title: "Unstage \(entry.path)") {
      try await gitClient.unstage(entry, in: requiredRepository())
    }
  }

  func unstageSelectedStatusEntry() async {
    guard canUnstageSelectedStatusEntry, let selectedStatusEntry else { return }
    await unstage(selectedStatusEntry)
  }

  func unstageAll() async {
    let entries = stagedChanges
    guard !entries.isEmpty else { return }
    await runMutation(title: "Unstage all") {
      try await gitClient.unstageAll(entries, in: requiredRepository())
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

  func ignore(_ entry: GitStatusEntry) async {
    guard entry.isUntracked else { return }
    await runMutation(title: "Ignore \(entry.path)") {
      try gitClient.ignorePath(entry.path, in: requiredRepository())
    }
  }

  func ignoreSelectedStatusEntry() async {
    guard canIgnoreSelectedStatusEntry, let selectedStatusEntry else { return }
    await ignore(selectedStatusEntry)
  }

  func ignoreExtension(_ entry: GitStatusEntry) async {
    guard entry.isUntracked,
          let pattern = GitIgnorePattern.extensionPattern(for: entry.path) else { return }
    await runMutation(title: "Ignore \(pattern)") {
      try gitClient.ignoreExtension(for: entry.path, in: requiredRepository())
    }
  }

  func ignoreSelectedStatusEntryExtension() async {
    guard canIgnoreSelectedStatusEntryExtension, let selectedStatusEntry else { return }
    await ignoreExtension(selectedStatusEntry)
  }

  func ignoreDirectory(_ entry: GitStatusEntry) async {
    guard entry.isUntracked,
          let pattern = GitIgnorePattern.directoryPattern(for: entry.path) else { return }
    await runMutation(title: "Ignore \(pattern)") {
      try gitClient.ignoreDirectory(for: entry.path, in: requiredRepository())
    }
  }

  func ignoreSelectedStatusEntryDirectory() async {
    guard canIgnoreSelectedStatusEntryDirectory, let selectedStatusEntry else { return }
    await ignoreDirectory(selectedStatusEntry)
  }

  func presentDiscardHunk(_ hunk: DiffHunk) {
    guard let selectedStatusEntry, !selectedStatusEntry.isStaged else { return }
    discardPatchRequest = DiscardPatchRequest(target: .hunk(hunk), path: selectedStatusEntry.path)
  }

  func presentDiscardLineChange(_ change: DiffLineChange) {
    guard let selectedStatusEntry, !selectedStatusEntry.isStaged else { return }
    discardPatchRequest = DiscardPatchRequest(target: .line(change), path: selectedStatusEntry.path)
  }

  func discardPatch() async {
    guard let request = discardPatchRequest else { return }
    discardPatchRequest = nil
    await runMutation(title: request.title) {
      switch request.target {
      case let .hunk(hunk):
        return try await gitClient.discardHunk(hunk, in: requiredRepository())
      case let .line(change):
        return try await gitClient.discardLineChange(change, in: requiredRepository())
      }
    }
  }

  func stageHunk(_ hunk: DiffHunk) async {
    await runMutation(title: "Stage hunk") {
      try await gitClient.stageHunk(hunk, in: requiredRepository())
    }
  }

  func unstageHunk(_ hunk: DiffHunk) async {
    await runMutation(title: "Unstage hunk") {
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

  func copyCurrentPatch() {
    guard canCopyCurrentPatch else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(diffText, forType: .string)
    commandResult = CommandResult(title: "Copy patch", output: "Copied current diff to the clipboard.", isError: false)
  }

  func applyPatchFromClipboard() async {
    let patch = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !patch.isEmpty else {
      commandResult = CommandResult(title: "Apply patch", output: "The clipboard does not contain patch text.", isError: true)
      errorMessage = "The clipboard does not contain patch text."
      return
    }

    await runMutation(title: "Apply patch") {
      try await gitClient.applyPatch(patch, in: requiredRepository())
    }
  }

  func commit() async {
    let message = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    if let commitReadinessIssue {
      commandResult = CommandResult(title: amendCommit ? "Amend commit" : "Commit", output: commitReadinessIssue, isError: true)
      errorMessage = commitReadinessIssue
      return
    }

    let committed = await runMutation(title: amendCommit ? "Amend commit" : "Commit") {
      try await gitClient.commit(message: message, amend: amendCommit, sign: signCommit, in: requiredRepository())
    }
    if committed {
      commitMessage = ""
      amendCommit = false
      rememberCommitMessage(message)
    }
  }

  func runRepositoryAction(_ action: RepositoryAction) async {
    if action == .pull, let pullReadinessIssue {
      commandResult = CommandResult(title: "Pull", output: pullReadinessIssue, isError: true)
      errorMessage = pullReadinessIssue
      return
    }

    if action == .push, let pushReadinessIssue {
      commandResult = CommandResult(title: pushActionTitle, output: pushReadinessIssue, isError: true)
      errorMessage = pushReadinessIssue
      return
    }

    if action == .push, shouldPublishCurrentBranch, let currentBranch, let publishRemote {
      await runMutation(title: "Publish \(currentBranch.shortName)") {
        try await gitClient.publishBranch(currentBranch.shortName, remote: publishRemote.name, in: requiredRepository())
      }
      return
    }

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
        let originalName = request.originalName ?? trimmedName
        var outputs: [String] = []
        if originalName != trimmedName {
          outputs.append(try await gitClient.renameRemote(from: originalName, to: trimmedName, in: requiredRepository()))
        }
        outputs.append(try await gitClient.setRemoteURL(name: trimmedName, url: trimmedURL, in: requiredRepository()))
        return outputs
          .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
          .joined(separator: "\n")
      }
    }
  }

  func presentRemoveRemote(_ remote: GitRemote) {
    removeRemoteRequest = RemoveRemoteRequest(remote: remote)
  }

  func removeRequestedRemote() async {
    guard let request = removeRemoteRequest else { return }
    removeRemoteRequest = nil
    await removeRemote(request.remote)
  }

  func fetchRemote(_ remote: GitRemote) async {
    await runMutation(title: "Fetch \(remote.name)") {
      try await gitClient.fetchRemote(remote, in: requiredRepository())
    }
  }

  func pruneRemote(_ remote: GitRemote) async {
    await runMutation(title: "Prune \(remote.name)") {
      try await gitClient.pruneRemote(remote, in: requiredRepository())
    }
  }

  func openRemoteInBrowser(_ remote: GitRemote) {
    guard let url = remote.githubWebURL else { return }
    NSWorkspace.shared.open(url)
  }

  func githubWebURL(forRemoteBranch branch: GitRef) -> URL? {
    guard let remoteName = branch.remoteName,
          let branchName = branch.remoteBranchName,
          let remote = snapshot.remotes.first(where: { $0.name == remoteName }) else {
      return nil
    }
    return remote.githubBranchWebURL(branchName: branchName)
  }

  func openRemoteBranchInBrowser(_ branch: GitRef) {
    guard let url = githubWebURL(forRemoteBranch: branch) else { return }
    NSWorkspace.shared.open(url)
  }

  func githubWebURL(forTag tag: GitRef) -> URL? {
    guard tag.kind == .tag else { return nil }
    return preferredGitHubRemote?.githubTagWebURL(tagName: tag.shortName)
  }

  func openTagInBrowser(_ tag: GitRef) {
    guard let url = githubWebURL(forTag: tag) else { return }
    NSWorkspace.shared.open(url)
  }

  func githubWebURL(forCommit commit: GitCommit) -> URL? {
    preferredGitHubRemote?.githubRepositoryTarget?.commitWebURL(commit.hash)
  }

  func openCommitInBrowser(_ commit: GitCommit) {
    guard let url = githubWebURL(forCommit: commit) else { return }
    NSWorkspace.shared.open(url)
  }

  private var preferredGitHubRemote: GitRemote? {
    snapshot.remotes.first(where: { $0.name == "origin" && $0.githubRepositoryTarget != nil })
      ?? snapshot.remotes.first(where: { $0.githubRepositoryTarget != nil })
  }

  func fetchRemoteBranch(_ branch: GitRef) async {
    await runMutation(title: "Fetch \(branch.shortName)") {
      try await gitClient.fetchRemoteBranch(branch, in: requiredRepository())
    }
  }

  private func removeRemote(_ remote: GitRemote) async {
    await runMutation(title: "Remove remote \(remote.name)") {
      try await gitClient.removeRemote(name: remote.name, in: requiredRepository())
    }
  }

  func presentCreateBranch() {
    branchRenameSource = nil
    branchStartPoint = selectedCommit?.hash
    tagRenameSource = nil
    tagTarget = nil
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .createBranch,
      title: "Create branch",
      message: selectedCommit.map { "Create a branch at \($0.shortHash)." } ?? "Create a branch at HEAD.",
      placeholder: "feature/new-work",
      defaultValue: "",
      primaryActionTitle: "Create"
    )
  }

  func presentCreateBranch(from ref: GitRef) {
    branchRenameSource = nil
    branchStartPoint = ref.shortName
    tagRenameSource = nil
    tagTarget = nil
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .createBranch,
      title: "Create branch",
      message: "Create a branch from \(ref.shortName).",
      placeholder: "feature/new-work",
      defaultValue: "",
      primaryActionTitle: "Create"
    )
  }

  func presentRenameBranch(_ branch: GitRef) {
    branchRenameSource = branch
    branchStartPoint = nil
    tagRenameSource = nil
    tagTarget = nil
    operationInput = branch.shortName
    operationRequest = GitOperationRequest(
      kind: .renameBranch,
      title: "Rename branch",
      message: "Rename \(branch.shortName).",
      placeholder: "feature/new-name",
      defaultValue: branch.shortName,
      primaryActionTitle: "Rename"
    )
  }

  func presentCreateTag() {
    branchRenameSource = nil
    branchStartPoint = nil
    tagRenameSource = nil
    tagTarget = selectedCommit?.hash
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .createTag,
      title: "Create tag",
      message: selectedCommit.map { "Create a tag at \($0.shortHash)." } ?? "Create a tag at HEAD.",
      placeholder: "v0.1.0",
      defaultValue: "",
      primaryActionTitle: "Create"
    )
  }

  func presentCreateTag(from ref: GitRef) {
    branchRenameSource = nil
    branchStartPoint = nil
    tagRenameSource = nil
    tagTarget = ref.shortName
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .createTag,
      title: "Create tag",
      message: "Create a tag at \(ref.shortName).",
      placeholder: "v0.1.0",
      defaultValue: "",
      primaryActionTitle: "Create"
    )
  }

  func presentRenameTag(_ tag: GitRef) {
    branchRenameSource = nil
    branchStartPoint = nil
    tagRenameSource = tag
    tagTarget = nil
    operationInput = tag.shortName
    operationRequest = GitOperationRequest(
      kind: .renameTag,
      title: "Rename tag",
      message: "Rename \(tag.shortName).",
      placeholder: "v0.2.0",
      defaultValue: tag.shortName,
      primaryActionTitle: "Rename"
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

    createWorktreeDestinationPath = defaultPath
    createWorktreeBranchName = ""
    createWorktreeRequest = CreateWorktreeRequest(
      startPointTitle: selectedCommit?.shortHash ?? "HEAD",
      defaultPath: defaultPath
    )
  }

  func presentStashPush(includeUntracked: Bool = false) {
    stashBranchSource = nil
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: includeUntracked ? .stashPushIncludeUntracked : .stashPush,
      title: includeUntracked ? "Create stash including untracked" : "Create stash",
      message: includeUntracked ? "Save tracked changes and untracked files to a stash." : "Save current working tree changes to a stash.",
      placeholder: "Optional stash message",
      defaultValue: "",
      primaryActionTitle: "Stash"
    )
  }

  func presentStashBranch(_ stash: GitStash) {
    stashBranchSource = stash
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .stashBranch,
      title: "Create branch from stash",
      message: "Create a branch from \(stash.index).",
      placeholder: "feature/stashed-work",
      defaultValue: "",
      primaryActionTitle: "Create"
    )
  }

  func presentStartBisect() {
    guard let selectedCommit, !snapshot.integrations.bisect.active else { return }
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: .bisectStart,
      title: "Start bisect",
      message: "Use \(selectedCommit.shortHash) as the known bad revision and enter a known good revision.",
      placeholder: "main~10 or a good commit hash",
      defaultValue: "",
      primaryActionTitle: "Start"
    )
  }

  func presentGitFlowStart(_ kind: GitFlowStartKind) {
    presentGitFlow(.start, kind: kind)
  }

  func presentGitFlowFinish(_ kind: GitFlowStartKind) {
    presentGitFlow(.finish, kind: kind)
  }

  private func presentGitFlow(_ action: GitFlowAction, kind: GitFlowStartKind) {
    operationInput = ""
    operationRequest = GitOperationRequest(
      kind: kind.operationKind(action: action),
      title: "\(action.title) Git-flow \(kind.title)",
      message: action == .start ? "Create a new \(kind.rawValue) branch using git-flow." : "Finish an existing \(kind.rawValue) branch using git-flow.",
      placeholder: kind == .release ? "0.1.0" : "name",
      defaultValue: "",
      primaryActionTitle: action.title
    )
  }

  func confirmOperation() async {
    guard let request = operationRequest else { return }
    let value = operationInput.trimmingCharacters(in: .whitespacesAndNewlines)
    let branchToRename = branchRenameSource
    let branchStartPoint = branchStartPoint
    let tagToRename = tagRenameSource
    let tagTarget = tagTarget
    let stashToBranch = stashBranchSource
    operationRequest = nil
    branchRenameSource = nil
    self.branchStartPoint = nil
    tagRenameSource = nil
    self.tagTarget = nil
    stashBranchSource = nil

    switch request.kind {
    case .createBranch:
      guard !value.isEmpty else { return }
      await runMutation(title: "Create branch \(value)") {
        try await gitClient.createBranch(named: value, startPoint: branchStartPoint, in: requiredRepository())
      }
    case .renameBranch:
      guard let branchToRename, !value.isEmpty else { return }
      await runMutation(title: "Rename branch \(branchToRename.shortName)") {
        try await gitClient.renameBranch(from: branchToRename.shortName, to: value, in: requiredRepository())
      }
    case .createTag:
      guard !value.isEmpty else { return }
      await runMutation(title: "Create tag \(value)") {
        try await gitClient.createTag(named: value, target: tagTarget, in: requiredRepository())
      }
    case .renameTag:
      guard let tagToRename, !value.isEmpty else { return }
      await runMutation(title: "Rename tag \(tagToRename.shortName)") {
        try await gitClient.renameTag(from: tagToRename.shortName, to: value, in: requiredRepository())
      }
    case .stashPush:
      await runMutation(title: "Create stash") {
        try await gitClient.stashPush(message: value.isEmpty ? nil : value, in: requiredRepository())
      }
    case .stashPushIncludeUntracked:
      await runMutation(title: "Create stash including untracked") {
        try await gitClient.stashPush(message: value.isEmpty ? nil : value, includeUntracked: true, in: requiredRepository())
      }
    case .stashBranch:
      guard let stashToBranch, !value.isEmpty else { return }
      await runMutation(title: "Create branch \(value)") {
        try await gitClient.stashBranch(value, stash: stashToBranch, in: requiredRepository())
      }
    case .bisectStart:
      guard let selectedCommit, !value.isEmpty else { return }
      await runMutation(title: "Start bisect") {
        try await gitClient.startBisect(bad: selectedCommit.hash, good: value, in: requiredRepository())
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
    case .gitFlowFeatureFinish:
      guard !value.isEmpty else { return }
      await finishGitFlow(kind: .feature, name: value)
    case .gitFlowReleaseFinish:
      guard !value.isEmpty else { return }
      await finishGitFlow(kind: .release, name: value)
    case .gitFlowHotfixFinish:
      guard !value.isEmpty else { return }
      await finishGitFlow(kind: .hotfix, name: value)
    }
  }

  func checkout(_ ref: GitRef) async {
    await runMutation(title: "Checkout \(ref.shortName)") {
      if let localName = ref.remoteTrackingLocalName {
        if localBranches.contains(where: { $0.shortName == localName }) {
          return try await gitClient.checkout(localName, in: requiredRepository())
        }
        return try await gitClient.checkoutTrackingRemote(ref, in: requiredRepository())
      }
      return try await gitClient.checkout(ref.shortName, in: requiredRepository())
    }
  }

  func checkoutSelectedCommit() async {
    guard let selectedCommit else { return }
    await runMutation(title: "Checkout \(selectedCommit.shortHash)") {
      try await gitClient.checkout(selectedCommit.hash, in: requiredRepository())
    }
  }

  func createRequestedWorktree() async {
    guard createWorktreeRequest != nil else { return }
    let destination = createWorktreeDestinationPath.trimmingCharacters(in: .whitespacesAndNewlines)
    let branch = createWorktreeBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
    createWorktreeRequest = nil
    createWorktreeDestinationPath = ""
    createWorktreeBranchName = ""
    guard !destination.isEmpty else { return }

    await runMutation(title: "Create worktree") {
      try await gitClient.createWorktree(
        at: destination,
        startPoint: selectedCommit?.hash ?? "HEAD",
        branch: branch.isEmpty ? nil : branch,
        in: requiredRepository()
      )
    }
  }

  func setCurrentBranchUpstream(_ remoteBranch: GitRef) async {
    guard let currentBranch else { return }
    await runMutation(title: "Track \(remoteBranch.shortName)") {
      try await gitClient.setUpstream(remoteBranch.shortName, for: currentBranch.shortName, in: requiredRepository())
    }
  }

  func pullBranch(_ branch: GitRef) async {
    guard branch.upstream != nil, !branch.upstreamGone else { return }
    await runMutation(title: "Pull \(branch.shortName)") {
      try await gitClient.pullBranch(branch, in: requiredRepository())
    }
  }

  func mergeReference(_ ref: GitRef) async {
    guard canUseAsRefOperationTarget(ref) else { return }
    await runMutation(title: "Merge \(ref.shortName)") {
      try await gitClient.mergeReference(ref, in: requiredRepository())
    }
  }

  func rebaseOntoReference(_ ref: GitRef) async {
    guard canUseAsRefOperationTarget(ref) else { return }
    await runMutation(title: "Rebase onto \(ref.shortName)") {
      try await gitClient.rebaseOntoReference(ref, in: requiredRepository())
    }
  }

  private func canUseAsRefOperationTarget(_ ref: GitRef) -> Bool {
    guard currentBranch != nil, !ref.isHead else { return false }
    return ref.kind == .localBranch || ref.kind == .tag || ref.remoteBranchName != nil
  }

  func unsetUpstream(_ branch: GitRef) async {
    await runMutation(title: "Unset upstream \(branch.shortName)") {
      try await gitClient.unsetUpstream(for: branch.shortName, in: requiredRepository())
    }
  }

  func pushTag(_ tag: GitRef, to remote: GitRemote) async {
    await runMutation(title: "Push tag \(tag.shortName)") {
      try await gitClient.pushTag(tag.shortName, remote: remote.name, in: requiredRepository())
    }
  }

  func pushBranch(_ branch: GitRef, to remote: GitRemote) async {
    await runMutation(title: "Push branch \(branch.shortName)") {
      try await gitClient.publishBranch(branch.shortName, remote: remote.name, in: requiredRepository())
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

  func presentDelete(_ ref: GitRef) {
    guard !ref.isHead else { return }
    deleteRefForce = false
    deleteRefRequest = DeleteRefRequest(ref: ref)
  }

  func deleteRequestedRef() async {
    guard let request = deleteRefRequest else { return }
    let force = deleteRefForce
    deleteRefRequest = nil
    deleteRefForce = false
    await delete(request.ref, force: force)
  }

  private func delete(_ ref: GitRef, force: Bool) async {
    await runMutation(title: "Delete \(ref.shortName)") {
      switch ref.kind {
      case .localBranch:
        return try await gitClient.deleteBranch(ref.shortName, force: force, in: requiredRepository())
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

  func presentRemoveWorktree(_ worktree: GitWorktree) {
    guard worktree.path != selectedRepository?.path else { return }
    removeWorktreeForce = false
    removeWorktreeRequest = RemoveWorktreeRequest(worktree: worktree)
  }

  func removeRequestedWorktree() async {
    guard let request = removeWorktreeRequest else { return }
    let force = removeWorktreeForce
    removeWorktreeRequest = nil
    removeWorktreeForce = false
    await removeWorktree(request.worktree, force: force)
  }

  private func removeWorktree(_ worktree: GitWorktree, force: Bool) async {
    await runMutation(title: "Remove worktree \(worktree.name)") {
      try await gitClient.removeWorktree(worktree, force: force, in: requiredRepository())
    }
  }

  func pruneWorktrees() async {
    await runMutation(title: "Prune worktrees") {
      try await gitClient.pruneWorktrees(in: requiredRepository())
    }
  }

  func presentRevisionCommand(_ command: GitRevisionCommand) {
    guard let selectedCommit else { return }
    revisionCommandRequest = RevisionCommandRequest(command: command, commit: selectedCommit)
  }

  func runRequestedRevisionCommand() async {
    guard let request = revisionCommandRequest else { return }
    revisionCommandRequest = nil
    await runMutation(title: request.command.resultTitle(shortHash: request.commit.shortHash)) {
      try await gitClient.runRevisionCommand(request.command, commit: request.commit, in: requiredRepository())
    }
  }

  func applyStash(_ stash: GitStash, pop: Bool) async {
    await runMutation(title: pop ? "Pop \(stash.index)" : "Apply \(stash.index)") {
      try await gitClient.stashApply(stash, pop: pop, in: requiredRepository())
    }
  }

  func copyStashPatch(_ stash: GitStash) async {
    do {
      let patch = try await gitClient.stashPatch(stash, algorithm: diffAlgorithm, in: requiredRepository())
      guard !patch.isEmpty else {
        commandResult = CommandResult(title: "Copy stash patch", output: "The stash patch is empty.", isError: true)
        errorMessage = "The stash patch is empty."
        return
      }
      PasteboardWriter.copy(patch)
      commandResult = CommandResult(title: "Copy stash patch", output: "Copied \(stash.index) patch to the clipboard.", isError: false)
    } catch {
      commandResult = CommandResult(title: "Copy stash patch", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func presentDropStash(_ stash: GitStash) {
    dropStashRequest = DropStashRequest(stash: stash)
  }

  func dropRequestedStash() async {
    guard let request = dropStashRequest else { return }
    dropStashRequest = nil
    await dropStash(request.stash)
  }

  private func dropStash(_ stash: GitStash) async {
    await runMutation(title: "Drop \(stash.index)") {
      try await gitClient.stashDrop(stash, in: requiredRepository())
    }
  }

  func updateSubmodules() async {
    await runMutation(title: "Update submodules") {
      try await gitClient.updateSubmodules(in: requiredRepository())
    }
  }

  func updateSubmodule(_ submodule: GitSubmodule) async {
    await runMutation(title: "Update submodule \(submodule.path)") {
      try await gitClient.updateSubmodule(submodule, in: requiredRepository())
    }
  }

  func openSubmodule(_ submodule: GitSubmodule) {
    guard let selectedRepository else { return }
    let url = submodule.directoryURL(in: selectedRepository)
    Task {
      await openRepository(at: url)
    }
  }

  func revealSubmoduleInFinder(_ submodule: GitSubmodule) {
    guard let selectedRepository else { return }
    NSWorkspace.shared.activateFileViewerSelecting([
      submodule.directoryURL(in: selectedRepository)
    ])
  }

  func openSubmoduleInTerminal(_ submodule: GitSubmodule) {
    guard let selectedRepository else { return }
    openDirectoryInTerminal(submodule.directoryURL(in: selectedRepository))
  }

  func lfsPull() async {
    await runMutation(title: "Git LFS pull") {
      try await gitClient.lfsPull(in: requiredRepository())
    }
  }

  func openLFSFile(_ file: GitLFSFile) {
    openFile(path: file.path)
  }

  func revealLFSFileInFinder(_ file: GitLFSFile) {
    guard let selectedRepository else { return }
    NSWorkspace.shared.activateFileViewerSelecting([
      file.fileURL(in: selectedRepository)
    ])
  }

  func lfsLockSelectedFile() async {
    guard let path = selectedPreviewPath else { return }
    await lfsLock(path: path)
  }

  func lfsLock(_ file: GitLFSFile) async {
    await lfsLock(path: file.path)
  }

  private func lfsLock(path: String) async {
    await runMutation(title: "Git LFS lock \(path)") {
      try await gitClient.lfsLock(path: path, in: requiredRepository())
    }
  }

  func lfsUnlockSelectedFile(force: Bool = false) async {
    guard let path = selectedPreviewPath else { return }
    await lfsUnlock(path: path, force: force)
  }

  func lfsUnlock(_ file: GitLFSFile, force: Bool = false) async {
    await lfsUnlock(path: file.path, force: force)
  }

  private func lfsUnlock(path: String, force: Bool) async {
    await runMutation(title: "Git LFS unlock \(path)") {
      try await gitClient.lfsUnlock(path: path, force: force, in: requiredRepository())
    }
  }

  func setCommitSigning(_ enabled: Bool) async {
    await runMutation(title: enabled ? "Enable GPG signing" : "Disable GPG signing") {
      try await gitClient.setCommitSigning(enabled, in: requiredRepository())
    }
  }

  func runInProgressOperation(_ action: GitInProgressOperationAction) async {
    guard let kind = snapshot.inProgressOperation.kind else { return }
    await runMutation(title: "\(kind.title) \(action.title)") {
      try await gitClient.runInProgressOperation(action, kind: kind, in: requiredRepository())
    }
  }

  func markBisect(_ mark: GitBisectMark) async {
    await runMutation(title: "Bisect \(mark.title)") {
      try await gitClient.markBisect(mark, in: requiredRepository())
    }
  }

  func resetBisect() async {
    await runMutation(title: "Reset bisect") {
      try await gitClient.resetBisect(in: requiredRepository())
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

  func finishGitFlow(kind: GitFlowStartKind, name: String) async {
    await runMutation(title: "Finish Git-flow \(kind.title)") {
      try await gitClient.finishGitFlow(kind: kind, name: name, in: requiredRepository())
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
    do {
      let lines = try await gitClient.blameLines(path: path, in: requiredRepository())
      blameDocument = GitBlameDocument(path: path, lines: lines)
    } catch {
      commandResult = CommandResult(title: "Blame \(path)", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func showFileHistoryForSelection() async {
    guard let path = selectedChangedFile?.path ?? selectedStatusEntry?.path else { return }
    do {
      let entries = try await gitClient.fileHistoryEntries(path: path, in: requiredRepository())
      fileHistoryDocument = GitFileHistoryDocument(path: path, entries: entries)
    } catch {
      commandResult = CommandResult(title: "File history \(path)", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func showLineHistory(_ change: DiffLineChange) async {
    guard let path = selectedChangedFile?.path ?? selectedStatusEntry?.path else { return }
    let startLine = change.historyStartLine
    let endLine = change.historyEndLine

    do {
      let entries = try await gitClient.lineHistoryEntries(
        path: path,
        startLine: startLine,
        endLine: endLine,
        in: requiredRepository()
      )
      lineHistoryDocument = GitLineHistoryDocument(path: path, startLine: startLine, endLine: endLine, entries: entries)
    } catch {
      commandResult = CommandResult(title: "Line history \(path)", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func fetchGitHubNotifications() async {
    guard let token = githubToken(commandTitle: "GitHub notifications") else { return }

    do {
      gitHubNotifications = try await gitHubClient.notifications(token: token)
      commandResult = CommandResult(
        title: "GitHub notifications",
        output: GitHubNotificationSummary.output(for: gitHubNotifications),
        isError: false
      )
    } catch {
      commandResult = CommandResult(title: "GitHub notifications", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func markGitHubNotificationsRead() async {
    guard let token = githubToken(commandTitle: "GitHub notifications") else { return }

    do {
      try await gitHubClient.markNotificationsRead(token: token)
      gitHubNotifications = []
      commandResult = CommandResult(title: "GitHub notifications", output: "Marked notifications as read.", isError: false)
    } catch {
      commandResult = CommandResult(title: "GitHub notifications", output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
    }
  }

  func openGitHubNotification(_ notification: GitHubNotification) {
    guard let url = notification.webURL else { return }
    NSWorkspace.shared.open(url)
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
    let target = snapshot.remotes.first(where: { $0.name == "origin" })?.githubRepositoryTarget
      ?? snapshot.remotes.compactMap(\.githubRepositoryTarget).first
    gitHubRepositoryRequest = GitHubRepositoryRequest(
      operation: .delete,
      owner: target?.owner ?? "",
      name: target?.name ?? selectedRepository?.name ?? "",
      repositoryDescription: "",
      isPrivate: false
    )
  }

  func runGitHubRepositoryOperation(_ request: GitHubRepositoryRequest) async {
    guard let token = githubToken(commandTitle: request.operation.title) else { return }
    if let validationMessage = request.validationMessage {
      commandResult = CommandResult(title: request.operation.title, output: validationMessage, isError: true)
      errorMessage = validationMessage
      return
    }
    gitHubRepositoryRequest = nil

    do {
      switch request.operation {
      case .create:
        let repository = try await gitHubClient.createRepository(
          token: token,
          name: request.normalizedName,
          description: request.normalizedDescription,
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
          owner: request.normalizedOwner,
          name: request.normalizedName
        )
        commandResult = CommandResult(
          title: request.operation.title,
          output: "Deleted \(request.normalizedOwner)/\(request.normalizedName).",
          isError: false
        )
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
      commandResult = CommandResult(title: "Interactive rebase", output: error.localizedDescription, isError: true)
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
    await runMutation(title: "Interactive rebase") {
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

  private func reconcileSelectedStatusEntry() {
    guard let current = selectedStatusEntry else { return }
    selectedStatusEntry = snapshot.status.first {
      $0.path == current.path && $0.originalPath == current.originalPath
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
        if FilePreviewSupport.isImagePath(file.path) {
          imageDiffSnapshot = await gitClient.imageDiffForStashFile(file, stash: stash, in: repository)
        }
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

  @discardableResult
  private func runMutation(title: String, operation: () async throws -> String) async -> Bool {
    do {
      let output = try await operation()
      commandResult = CommandResult(title: title, output: output.isEmpty ? "Completed." : output, isError: false)
      if autoRefreshAfterMutations {
        await refreshAll()
      }
      return true
    } catch {
      commandResult = CommandResult(title: title, output: error.localizedDescription, isError: true)
      errorMessage = error.localizedDescription
      return false
    }
  }

  private var autoRefreshAfterMutations: Bool {
    guard UserDefaults.standard.object(forKey: autoRefreshKey) != nil else {
      return true
    }
    return UserDefaults.standard.bool(forKey: autoRefreshKey)
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

  private func githubToken(commandTitle: String) -> String? {
    let token = UserDefaults.standard.string(forKey: "bonsai.githubToken")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !token.isEmpty else {
      let message = "Add a GitHub personal access token in Settings first."
      commandResult = CommandResult(title: commandTitle, output: message, isError: true)
      errorMessage = message
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
    blameDocument = nil
    fileHistoryDocument = nil
    lineHistoryDocument = nil
    createWorktreeRequest = nil
    createWorktreeDestinationPath = ""
    createWorktreeBranchName = ""
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
    saveRecentCommitMessages()
  }

  func clearRecentCommitMessages() {
    recentCommitMessages.removeAll()
    saveRecentCommitMessages()
  }

  private func saveRecentCommitMessages() {
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

  static func cloneDestination(parentDirectory: URL, remoteURL: String) -> URL {
    parentDirectory.appending(
      path: repositoryName(fromRemoteURL: remoteURL)
    )
  }
}

enum RepositoryStoreError: LocalizedError {
  case noRepository

  var errorDescription: String? {
    "No repository is selected."
  }
}
