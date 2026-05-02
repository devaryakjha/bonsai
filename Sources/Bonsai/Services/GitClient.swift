import Foundation

struct GitClient {
  private let runner = ProcessRunner()
  private let gitExecutable = "/usr/bin/env"

  func validateRepository(at url: URL) async throws {
    _ = try await git(["rev-parse", "--show-toplevel"], in: url)
  }

  func cloneRepository(from remoteURL: String, to destination: URL) async throws -> String {
    let parent = destination.deletingLastPathComponent()
    let output = try await git(["clone", remoteURL, destination.path(percentEncoded: false)], in: parent)
    return output.combinedOutput
  }

  func initializeRepository(at destination: URL) async throws -> String {
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    let output = try await git(["init"], in: destination)
    return output.combinedOutput
  }

  func snapshot(for repository: GitRepository, selectedCommit: GitCommit?) async throws -> RepositorySnapshot {
    async let status = status(in: repository)
    async let commits = commits(in: repository)
    async let refs = refs(in: repository)
    async let remotes = remotes(in: repository)
    async let stashes = stashes(in: repository)
    async let submodules = submodules(in: repository)
    async let worktrees = worktrees(in: repository)
    async let integrations = integrations(in: repository)
    async let inProgressOperation = inProgressOperation(in: repository)

    let resolvedCommits = try await commits
    let commitForFiles = selectedCommit ?? resolvedCommits.first
    let files = try await changedFiles(in: repository, commit: commitForFiles)

    return try await RepositorySnapshot(
      status: status,
      commits: resolvedCommits,
      changedFiles: files,
      refs: refs,
      remotes: remotes,
      stashes: stashes,
      submodules: submodules,
      worktrees: worktrees,
      integrations: integrations,
      inProgressOperation: inProgressOperation
    )
  }

  func status(in repository: GitRepository) async throws -> [GitStatusEntry] {
    let output = try await git(["status", "--porcelain=v1", "--untracked-files=all"], in: repository.url)
    return GitParsers.parseStatus(output.stdout)
  }

  func commits(in repository: GitRepository) async throws -> [GitCommit] {
    guard await commandSucceeds(["rev-parse", "--verify", "HEAD"], in: repository) else {
      return []
    }

    let format = "%x1f%H%x1f%h%x1f%an%x1f%ae%x1f%ad%x1f%s%x1f%D"
    let output = try await git([
      "log",
      "--graph",
      "--date=iso-strict",
      "--decorate=short",
      "--pretty=format:\(format)",
      "-n",
      "300"
    ], in: repository.url)
    return GitParsers.parseCommits(output.stdout)
  }

  func commit(revision: String, in repository: GitRepository) async throws -> GitCommit {
    let format = "%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s%x1f%D"
    let output = try await git([
      "log",
      "--date=iso-strict",
      "--decorate=short",
      "--pretty=format:\(format)",
      "-n",
      "1",
      revision
    ], in: repository.url)
    guard let commit = GitParsers.parseCommits(output.stdout).first else {
      throw GitClientError.commitNotFound(revision)
    }
    return commit
  }

  func refs(in repository: GitRepository) async throws -> [GitRef] {
    let format = "%(refname)%1f%(objectname:short)%1f%(upstream:short)%1f%(HEAD)%1f%(upstream:track)"
    let output = try await git([
      "for-each-ref",
      "refs/heads",
      "refs/remotes",
      "refs/tags",
      "--format=\(format)"
    ], in: repository.url)
    return GitParsers.parseRefs(output.stdout)
  }

  func remotes(in repository: GitRepository) async throws -> [GitRemote] {
    let output = try await git(["remote", "-v"], in: repository.url)
    return GitParsers.parseRemotes(output.stdout)
  }

  func addRemote(name: String, url: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.addRemoteArguments(name: name, url: url), in: repository)
  }

  static func addRemoteArguments(name: String, url: String) -> [String] {
    ["remote", "add", name, url]
  }

  func setRemoteURL(name: String, url: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.setRemoteURLArguments(name: name, url: url), in: repository)
  }

  static func setRemoteURLArguments(name: String, url: String) -> [String] {
    ["remote", "set-url", name, url]
  }

  func renameRemote(from oldName: String, to newName: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.renameRemoteArguments(from: oldName, to: newName), in: repository)
  }

  static func renameRemoteArguments(from oldName: String, to newName: String) -> [String] {
    ["remote", "rename", oldName, newName]
  }

  func removeRemote(name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.removeRemoteArguments(name: name), in: repository)
  }

  static func removeRemoteArguments(name: String) -> [String] {
    ["remote", "remove", name]
  }

  func fetchRemote(_ remote: GitRemote, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.fetchRemoteArguments(remote), in: repository)
  }

  static func fetchRemoteArguments(_ remote: GitRemote) -> [String] {
    ["fetch", "--prune", remote.name]
  }

  func pruneRemote(_ remote: GitRemote, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.pruneRemoteArguments(remote), in: repository)
  }

  static func pruneRemoteArguments(_ remote: GitRemote) -> [String] {
    ["remote", "prune", remote.name]
  }

  func fetchRemoteBranch(_ branch: GitRef, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.fetchRemoteBranchArguments(branch), in: repository)
  }

  static func fetchRemoteBranchArguments(_ branch: GitRef) throws -> [String] {
    guard let remoteName = branch.remoteName,
          let branchName = branch.remoteBranchName else {
      throw GitClientError.invalidRemoteBranch(branch.shortName)
    }
    return ["fetch", remoteName, "\(branchName):refs/remotes/\(remoteName)/\(branchName)"]
  }

  func stashes(in repository: GitRepository) async throws -> [GitStash] {
    let output = try? await git(["stash", "list"], in: repository.url)
    return GitParsers.parseStashes(output?.stdout ?? "")
  }

  func submodules(in repository: GitRepository) async throws -> [GitSubmodule] {
    let output = try? await git(["submodule", "status", "--recursive"], in: repository.url)
    return GitParsers.parseSubmodules(output?.stdout ?? "")
  }

  func worktrees(in repository: GitRepository) async throws -> [GitWorktree] {
    let output = try? await git(["worktree", "list", "--porcelain"], in: repository.url)
    return GitParsers.parseWorktrees(output?.stdout ?? "")
  }

  func integrations(in repository: GitRepository) async -> GitIntegrationStatus {
    async let lfsAvailable = commandSucceeds(["lfs", "version"], in: repository)
    async let gitFlowAvailable = commandSucceeds(["flow", "version"], in: repository)
    async let lfsFiles = lfsFiles(in: repository)
    async let gpgSigning = configValue("commit.gpgsign", in: repository)
    async let signingKey = configValue("user.signingkey", in: repository)
    async let flowMain = configValue("gitflow.branch.master", in: repository)
    async let flowDevelop = configValue("gitflow.branch.develop", in: repository)
    async let bisect = bisectStatus(in: repository)

    let mainBranch = await flowMain
    let developBranch = await flowDevelop
    return await GitIntegrationStatus(
      lfsAvailable: lfsAvailable,
      lfsFiles: lfsFiles,
      gpgSigningEnabled: ["true", "yes", "on", "1"].contains((gpgSigning ?? "").lowercased()),
      signingKey: signingKey,
      gitFlowAvailable: gitFlowAvailable,
      gitFlowInitialized: mainBranch != nil && developBranch != nil,
      gitFlowMainBranch: mainBranch,
      gitFlowDevelopBranch: developBranch,
      bisect: bisect
    )
  }

  func changedFiles(in repository: GitRepository, commit: GitCommit?) async throws -> [GitChangedFile] {
    guard let commit else { return [] }
    let output = try await git(["show", "--format=", "--name-status", commit.hash], in: repository.url)
    return GitParsers.parseChangedFiles(output.stdout)
  }

  func changedFiles(in repository: GitRepository, stash: GitStash?) async throws -> [GitChangedFile] {
    guard let stash else { return [] }
    let output = try await git(["stash", "show", "--name-status", stash.index], in: repository.url)
    return GitParsers.parseChangedFiles(output.stdout)
  }

  func treeEntries(in repository: GitRepository, commit: GitCommit?, path: String = "") async throws -> [GitTreeEntry] {
    guard let commit else { return [] }
    let target = path.isEmpty ? commit.hash : "\(commit.hash):\(path)"
    let output = try await git(["ls-tree", "-z", target], in: repository.url)
    return GitParsers.parseTreeEntries(output.stdout, basePath: path)
  }

  func blobText(path: String, commit: GitCommit, in repository: GitRepository) async throws -> String {
    let output = try await gitData(["show", "\(commit.hash):\(path)"], in: repository.url)
    if let text = String(data: output.stdout, encoding: .utf8) {
      return text
    }
    return "Binary file preview is not available for \(path)."
  }

  func diffForWorkingTreeFile(
    _ entry: GitStatusEntry,
    staged: Bool,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let args = staged
      ? diffArguments(["--cached", "--", entry.path], algorithm: algorithm, whitespaceMode: whitespaceMode)
      : diffArguments(["--", entry.path], algorithm: algorithm, whitespaceMode: whitespaceMode)
    let output = try await git(args, in: repository.url)
    return output.stdout
  }

  func diffForCommitFile(
    _ file: GitChangedFile,
    commit: GitCommit,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let output = try await git([
      "show",
      "--format=",
      "--no-ext-diff",
      "--no-color",
      "--find-renames",
      "--find-copies",
      "--diff-algorithm=\(algorithm.rawValue)",
      "--indent-heuristic",
    ] + whitespaceMode.gitArguments + [
      commit.hash,
      "--",
      file.path
    ], in: repository.url)
    return output.stdout
  }

  func diffForStashFile(
    _ file: GitChangedFile,
    stash: GitStash,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let output = try await git(
      diffArguments(["\(stash.index)^1", stash.index, "--", file.path], algorithm: algorithm, whitespaceMode: whitespaceMode),
      in: repository.url
    )
    return output.stdout
  }

  func imageDiffForWorkingTreeFile(_ entry: GitStatusEntry, in repository: GitRepository) async -> ImageDiffSnapshot {
    let oldPath = entry.originalPath ?? entry.path
    let oldData = entry.isUntracked ? nil : try? await gitData(["show", "HEAD:\(oldPath)"], in: repository.url).stdout
    let newData: Data?
    if entry.isStaged {
      newData = try? await gitData(["show", ":\(entry.path)"], in: repository.url).stdout
    } else if entry.kind == .deleted {
      newData = nil
    } else {
      newData = try? Data(contentsOf: repository.url.appending(path: entry.path))
    }
    return ImageDiffSnapshot(path: entry.path, oldData: oldData, newData: newData)
  }

  func imageDiffForCommitFile(_ file: GitChangedFile, commit: GitCommit, in repository: GitRepository) async -> ImageDiffSnapshot {
    let oldPath = file.oldPath ?? file.path
    let oldData = try? await gitData(["show", "\(commit.hash)^:\(oldPath)"], in: repository.url).stdout
    let newData = file.status.hasPrefix("D") ? nil : try? await gitData(["show", "\(commit.hash):\(file.path)"], in: repository.url).stdout
    return ImageDiffSnapshot(path: file.path, oldData: oldData, newData: newData)
  }

  func imageDiffForStashFile(_ file: GitChangedFile, stash: GitStash, in repository: GitRepository) async -> ImageDiffSnapshot {
    let oldPath = file.oldPath ?? file.path
    let oldData = file.status.hasPrefix("A") ? nil : try? await gitData(["show", "\(stash.index)^1:\(oldPath)"], in: repository.url).stdout
    let newData = file.status.hasPrefix("D") ? nil : try? await gitData(["show", "\(stash.index):\(file.path)"], in: repository.url).stdout
    return ImageDiffSnapshot(path: file.path, oldData: oldData, newData: newData)
  }

  func stage(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.stageArguments(entry), in: repository)
  }

  static func stageArguments(_ entry: GitStatusEntry) -> [String] {
    ["add", "--", entry.path]
  }

  func stageAll(_ entries: [GitStatusEntry], in repository: GitRepository) async throws -> String {
    guard !entries.isEmpty else { return "" }
    return try await runRaw(Self.stageAllArguments(entries), in: repository)
  }

  static func stageAllArguments(_ entries: [GitStatusEntry]) -> [String] {
    ["add", "--all", "--"] + entries.map(\.path)
  }

  func unstage(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.unstageArguments(entry), in: repository)
  }

  static func unstageArguments(_ entry: GitStatusEntry) -> [String] {
    ["restore", "--staged", "--", entry.path]
  }

  func unstageAll(_ entries: [GitStatusEntry], in repository: GitRepository) async throws -> String {
    guard !entries.isEmpty else { return "" }
    let hasHead = await commandSucceeds(["rev-parse", "--verify", "HEAD"], in: repository)
    return try await runRaw(Self.unstageAllArguments(entries, hasHead: hasHead), in: repository)
  }

  static func unstageAllArguments(_ entries: [GitStatusEntry], hasHead: Bool) -> [String] {
    let paths = entries.map(\.path)
    if hasHead {
      return ["restore", "--staged", "--"] + paths
    }
    return ["rm", "--cached", "-r", "--"] + paths
  }

  func discard(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    if entry.isUntracked {
      return try await runRaw(Self.discardUntrackedArguments(entry), in: repository)
    }

    var outputs: [String] = []
    if entry.isStaged {
      outputs.append(try await unstage(entry, in: repository))
    }
    outputs.append(try await runRaw(Self.discardWorktreeArguments(entry), in: repository))
    return outputs.filter { !$0.isEmpty }.joined(separator: "\n")
  }

  static func discardUntrackedArguments(_ entry: GitStatusEntry) -> [String] {
    ["clean", "-f", "--", entry.path]
  }

  static func discardWorktreeArguments(_ entry: GitStatusEntry) -> [String] {
    ["restore", "--worktree", "--", entry.path]
  }

  func ignorePath(_ path: String, in repository: GitRepository) throws -> String {
    let pattern = GitIgnorePattern.repositoryRootPattern(for: path)
    return try ignorePattern(pattern, label: path, in: repository)
  }

  func ignoreExtension(for path: String, in repository: GitRepository) throws -> String {
    guard let pattern = GitIgnorePattern.extensionPattern(for: path) else {
      return "No file extension found for \(path)."
    }
    return try ignorePattern(pattern, label: pattern, in: repository)
  }

  func ignoreDirectory(for path: String, in repository: GitRepository) throws -> String {
    guard let pattern = GitIgnorePattern.directoryPattern(for: path) else {
      return "No containing folder found for \(path)."
    }
    return try ignorePattern(pattern, label: pattern, in: repository)
  }

  private func ignorePattern(_ pattern: String, label: String, in repository: GitRepository) throws -> String {
    let ignoreURL = repository.url.appending(path: ".gitignore")
    let existing = (try? String(contentsOf: ignoreURL, encoding: .utf8)) ?? ""
    let existingPatterns = Set(existing.split(separator: "\n").map(String.init))
    if existingPatterns.contains(pattern) {
      return "Already ignored \(label)."
    }

    var updated = existing
    if !updated.isEmpty && !updated.hasSuffix("\n") {
      updated.append("\n")
    }
    updated.append("\(pattern)\n")
    try updated.write(to: ignoreURL, atomically: true, encoding: .utf8)
    return "Added \(pattern) to .gitignore."
  }

  func stageHunk(_ hunk: DiffHunk, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.stageHunkArguments(), in: repository.url, standardInput: hunk.patch)
    return output.combinedOutput
  }

  static func stageHunkArguments() -> [String] {
    ["apply", "--cached"]
  }

  func unstageHunk(_ hunk: DiffHunk, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.unstageHunkArguments(), in: repository.url, standardInput: hunk.patch)
    return output.combinedOutput
  }

  static func unstageHunkArguments() -> [String] {
    ["apply", "--cached", "--reverse"]
  }

  func stageLineChange(_ change: DiffLineChange, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.stageLineChangeArguments(), in: repository.url, standardInput: change.patch)
    return output.combinedOutput
  }

  static func stageLineChangeArguments() -> [String] {
    ["apply", "--cached", "--unidiff-zero"]
  }

  func unstageLineChange(_ change: DiffLineChange, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.unstageLineChangeArguments(), in: repository.url, standardInput: change.patch)
    return output.combinedOutput
  }

  static func unstageLineChangeArguments() -> [String] {
    ["apply", "--cached", "--reverse", "--unidiff-zero"]
  }

  func discardHunk(_ hunk: DiffHunk, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.discardHunkArguments(), in: repository.url, standardInput: hunk.patch)
    return output.combinedOutput
  }

  static func discardHunkArguments() -> [String] {
    ["apply", "--reverse"]
  }

  func discardLineChange(_ change: DiffLineChange, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.discardLineChangeArguments(), in: repository.url, standardInput: change.patch)
    return output.combinedOutput
  }

  static func discardLineChangeArguments() -> [String] {
    ["apply", "--reverse", "--unidiff-zero"]
  }

  func applyPatch(_ patch: String, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.applyPatchArguments(), in: repository.url, standardInput: patch)
    return output.combinedOutput
  }

  static func applyPatchArguments() -> [String] {
    ["apply"]
  }

  func commit(message: String, amend: Bool, sign: Bool, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.commitArguments(message: message, amend: amend, sign: sign), in: repository.url)
    return output.combinedOutput
  }

  static func commitArguments(message: String, amend: Bool, sign: Bool) -> [String] {
    var args = ["commit", "-m", message]
    if amend { args.append("--amend") }
    if sign { args.append("-S") }
    return args
  }

  func runAction(_ action: RepositoryAction, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.repositoryActionArguments(action), in: repository)
  }

  static func repositoryActionArguments(_ action: RepositoryAction) -> [String] {
    switch action {
    case .fetch:
      return ["fetch", "--all", "--prune"]
    case .pull:
      return ["pull", "--ff-only"]
    case .push:
      return ["push"]
    }
  }

  func publishBranch(_ branch: String, remote: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.publishBranchArguments(branch, remote: remote), in: repository)
  }

  static func publishBranchArguments(_ branch: String, remote: String) -> [String] {
    ["push", "-u", remote, branch]
  }

  func forcePushWithLease(_ branch: GitRef, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.forcePushWithLeaseArguments(branch), in: repository)
  }

  static func forcePushWithLeaseArguments(_ branch: GitRef) throws -> [String] {
    guard let remoteName = branch.upstreamRemoteName,
          let upstreamBranchName = branch.upstreamBranchName else {
      throw GitClientError.invalidBranchUpstream(branch.shortName)
    }
    return [
      "push",
      "--force-with-lease",
      remoteName,
      "\(branch.shortName):\(upstreamBranchName)"
    ]
  }

  func pullBranch(_ branch: GitRef, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.pullBranchArguments(branch), in: repository)
  }

  static func pullBranchArguments(_ branch: GitRef) throws -> [String] {
    if branch.isHead {
      return ["pull", "--ff-only"]
    }
    guard let remoteName = branch.upstreamRemoteName,
          let upstreamBranchName = branch.upstreamBranchName else {
      throw GitClientError.invalidBranchUpstream(branch.shortName)
    }
    return [
      "fetch",
      remoteName,
      "\(upstreamBranchName):refs/remotes/\(remoteName)/\(upstreamBranchName)",
      "\(upstreamBranchName):refs/heads/\(branch.shortName)"
    ]
  }

  func mergeReference(_ ref: GitRef, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.mergeReferenceArguments(ref), in: repository)
  }

  static func mergeReferenceArguments(_ ref: GitRef) -> [String] {
    ["merge", "--no-edit", ref.shortName]
  }

  func rebaseOntoReference(_ ref: GitRef, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.rebaseOntoReferenceArguments(ref), in: repository)
  }

  static func rebaseOntoReferenceArguments(_ ref: GitRef) -> [String] {
    ["rebase", ref.shortName]
  }

  func pushTag(_ tag: String, remote: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.pushTagArguments(tag, remote: remote), in: repository)
  }

  static func pushTagArguments(_ tag: String, remote: String) -> [String] {
    ["push", remote, tag]
  }

  func deleteRemoteTag(_ tag: String, remote: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.deleteRemoteTagArguments(tag, remote: remote), in: repository)
  }

  static func deleteRemoteTagArguments(_ tag: String, remote: String) -> [String] {
    ["push", remote, ":refs/tags/\(tag)"]
  }

  func runRaw(_ arguments: [String], in repository: GitRepository) async throws -> String {
    let output = try await git(arguments, in: repository.url)
    return output.combinedOutput
  }

  func runRevisionCommand(_ command: GitRevisionCommand, commit: GitCommit, in repository: GitRepository) async throws -> String {
    try await runRaw(command.arguments(commitHash: commit.hash), in: repository)
  }

  func createBranch(named name: String, startPoint: String?, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.createBranchArguments(named: name, startPoint: startPoint), in: repository)
  }

  static func createBranchArguments(named name: String, startPoint: String?) -> [String] {
    var args = ["branch", name]
    if let startPoint, !startPoint.isEmpty {
      args.append(startPoint)
    }
    return args
  }

  func renameBranch(from oldName: String, to newName: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.renameBranchArguments(from: oldName, to: newName), in: repository)
  }

  static func renameBranchArguments(from oldName: String, to newName: String) -> [String] {
    ["branch", "-m", oldName, newName]
  }

  func createTag(named name: String, target: String?, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.createTagArguments(named: name, target: target), in: repository)
  }

  static func createTagArguments(named name: String, target: String?) -> [String] {
    var args = ["tag", name]
    if let target, !target.isEmpty {
      args.append(target)
    }
    return args
  }

  func createAnnotatedTag(named name: String, message: String, target: String?, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.createAnnotatedTagArguments(named: name, message: message, target: target), in: repository)
  }

  static func createAnnotatedTagArguments(named name: String, message: String, target: String?) -> [String] {
    var args = ["tag", "-a", name, "-m", message]
    if let target, !target.isEmpty {
      args.append(target)
    }
    return args
  }

  func renameTag(from oldName: String, to newName: String, in repository: GitRepository) async throws -> String {
    let oldRef = "refs/tags/\(oldName)"
    let newRef = "refs/tags/\(newName)"
    let object = try await git(["rev-parse", oldRef], in: repository.url).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let create = try await git(["update-ref", newRef, object, ""], in: repository.url)
    let delete = try await git(["update-ref", "-d", oldRef], in: repository.url)
    return [create.combinedOutput, delete.combinedOutput]
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }

  func checkout(_ ref: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.checkoutArguments(ref), in: repository)
  }

  static func checkoutArguments(_ ref: String) -> [String] {
    ["checkout", ref]
  }

  func checkoutTrackingRemote(_ ref: GitRef, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.checkoutTrackingRemoteArguments(ref), in: repository)
  }

  static func checkoutTrackingRemoteArguments(_ ref: GitRef) -> [String] {
    ["checkout", "--track", ref.shortName]
  }

  func setUpstream(_ upstream: String, for branch: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.setUpstreamArguments(upstream, for: branch), in: repository)
  }

  static func setUpstreamArguments(_ upstream: String, for branch: String) -> [String] {
    ["branch", "--set-upstream-to=\(upstream)", branch]
  }

  func unsetUpstream(for branch: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.unsetUpstreamArguments(for: branch), in: repository)
  }

  static func unsetUpstreamArguments(for branch: String) -> [String] {
    ["branch", "--unset-upstream", branch]
  }

  func reset(to commit: GitCommit, mode: ResetMode, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.resetArguments(to: commit.hash, mode: mode), in: repository)
  }

  func reset(to entry: GitReflogEntry, mode: ResetMode, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.resetArguments(to: entry.hash, mode: mode), in: repository)
  }

  static func resetArguments(to revision: String, mode: ResetMode) -> [String] {
    ["reset", mode.flag, revision]
  }

  func deleteBranch(_ name: String, force: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.deleteBranchArguments(name, force: force), in: repository)
  }

  static func deleteBranchArguments(_ name: String, force: Bool) -> [String] {
    ["branch", force ? "-D" : "-d", name]
  }

  func deleteRemoteBranch(_ branch: GitRef, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.deleteRemoteBranchArguments(branch), in: repository)
  }

  static func deleteRemoteBranchArguments(_ branch: GitRef) throws -> [String] {
    guard let remoteName = branch.remoteName,
          let branchName = branch.remoteBranchName else {
      throw GitClientError.invalidRemoteBranch(branch.shortName)
    }
    return ["push", remoteName, "--delete", branchName]
  }

  func deleteTag(_ name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.deleteTagArguments(name), in: repository)
  }

  static func deleteTagArguments(_ name: String) -> [String] {
    ["tag", "-d", name]
  }

  func createWorktree(at path: String, startPoint: String, branch: String? = nil, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.createWorktreeArguments(at: path, startPoint: startPoint, branch: branch), in: repository)
  }

  static func createWorktreeArguments(at path: String, startPoint: String, branch: String? = nil) -> [String] {
    if let branch, !branch.isEmpty {
      return ["worktree", "add", "-b", branch, path, startPoint]
    }
    return ["worktree", "add", "--detach", path, startPoint]
  }

  func removeWorktree(_ worktree: GitWorktree, force: Bool = false, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.removeWorktreeArguments(worktree, force: force), in: repository)
  }

  static func removeWorktreeArguments(_ worktree: GitWorktree, force: Bool = false) -> [String] {
    var args = ["worktree", "remove"]
    if force {
      args.append("--force")
    }
    args.append(worktree.path)
    return args
  }

  func pruneWorktrees(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.pruneWorktreesArguments(), in: repository)
  }

  static func pruneWorktreesArguments() -> [String] {
    ["worktree", "prune"]
  }

  func stashPush(message: String?, includeUntracked: Bool = false, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.stashPushArguments(message: message, includeUntracked: includeUntracked), in: repository)
  }

  static func stashPushArguments(message: String?, includeUntracked: Bool = false) -> [String] {
    var args = ["stash", "push"]
    if includeUntracked {
      args.append("--include-untracked")
    }
    if let message, !message.isEmpty {
      args += ["-m", message]
    }
    return args
  }

  func stashApply(_ stash: GitStash, pop: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.stashApplyArguments(stash, pop: pop), in: repository)
  }

  static func stashApplyArguments(_ stash: GitStash, pop: Bool) -> [String] {
    ["stash", pop ? "pop" : "apply", stash.index]
  }

  func stashPatch(
    _ stash: GitStash,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let output = try await git([
      "stash",
      "show",
      "--patch",
      "--no-color",
      "--find-renames",
      "--find-copies",
      "--include-untracked",
      "--diff-algorithm=\(algorithm.rawValue)",
    ] + whitespaceMode.gitArguments + [
      stash.index
    ], in: repository.url)
    return output.stdout
  }

  func stashDrop(_ stash: GitStash, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.stashDropArguments(stash), in: repository)
  }

  static func stashDropArguments(_ stash: GitStash) -> [String] {
    ["stash", "drop", stash.index]
  }

  func stashBranch(_ branch: String, stash: GitStash, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.stashBranchArguments(branch, stash: stash), in: repository)
  }

  static func stashBranchArguments(_ branch: String, stash: GitStash) -> [String] {
    ["stash", "branch", branch, stash.index]
  }

  func updateSubmodules(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.updateSubmodulesArguments(), in: repository)
  }

  static func updateSubmodulesArguments() -> [String] {
    ["submodule", "update", "--init", "--recursive"]
  }

  func updateSubmodule(_ submodule: GitSubmodule, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.updateSubmoduleArguments(submodule), in: repository)
  }

  static func updateSubmoduleArguments(_ submodule: GitSubmodule) -> [String] {
    updateSubmodulesArguments() + ["--", submodule.path]
  }

  func lfsPull(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.lfsPullArguments(), in: repository)
  }

  static func lfsPullArguments() -> [String] {
    ["lfs", "pull"]
  }

  func lfsFetch(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.lfsFetchArguments(), in: repository)
  }

  static func lfsFetchArguments() -> [String] {
    ["lfs", "fetch"]
  }

  func lfsCheckout(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.lfsCheckoutArguments(), in: repository)
  }

  static func lfsCheckoutArguments() -> [String] {
    ["lfs", "checkout"]
  }

  func lfsPrune(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.lfsPruneArguments(), in: repository)
  }

  static func lfsPruneArguments() -> [String] {
    ["lfs", "prune"]
  }

  func lfsLock(path: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["lfs", "lock", path], in: repository)
  }

  func lfsUnlock(path: String, force: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.lfsUnlockArguments(path: path, force: force), in: repository)
  }

  static func lfsUnlockArguments(path: String, force: Bool) -> [String] {
    var args = ["lfs", "unlock"]
    if force {
      args.append("--force")
    }
    args.append(path)
    return args
  }

  func setCommitSigning(_ enabled: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(["config", "commit.gpgsign", enabled ? "true" : "false"], in: repository)
  }

  func runInProgressOperation(_ action: GitInProgressOperationAction, kind: GitInProgressOperationKind, in repository: GitRepository) async throws -> String {
    try await runRaw([kind.command, action.flag], in: repository)
  }

  func startBisect(bad: String, good: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["bisect", "start", bad, good], in: repository)
  }

  func markBisect(_ mark: GitBisectMark, in repository: GitRepository) async throws -> String {
    try await runRaw(["bisect", mark.rawValue], in: repository)
  }

  func resetBisect(in repository: GitRepository) async throws -> String {
    try await runRaw(["bisect", "reset"], in: repository)
  }

  func initializeGitFlow(in repository: GitRepository) async throws -> String {
    try await runRaw(["flow", "init", "-d"], in: repository)
  }

  func startGitFlow(kind: GitFlowStartKind, name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["flow", kind.rawValue, "start", name], in: repository)
  }

  func finishGitFlow(kind: GitFlowStartKind, name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["flow", kind.rawValue, "finish", name], in: repository)
  }

  func resolveConflict(_ entry: GitStatusEntry, choice: ConflictResolutionChoice, in repository: GitRepository) async throws -> String {
    switch choice {
    case .ours:
      let checkout = try await git(["checkout", "--ours", "--", entry.path], in: repository.url)
      let add = try await git(["add", "--", entry.path], in: repository.url)
      return [checkout.combinedOutput, add.combinedOutput].filter { !$0.isEmpty }.joined(separator: "\n")
    case .theirs:
      let checkout = try await git(["checkout", "--theirs", "--", entry.path], in: repository.url)
      let add = try await git(["add", "--", entry.path], in: repository.url)
      return [checkout.combinedOutput, add.combinedOutput].filter { !$0.isEmpty }.joined(separator: "\n")
    case .markResolved:
      return try await runRaw(["add", "--", entry.path], in: repository)
    }
  }

  func conflictPreviews(_ entry: GitStatusEntry, in repository: GitRepository) async -> [ConflictPreview] {
    var previews: [ConflictPreview] = []
    for side in ConflictPreviewSide.allCases {
      let text: String
      if let stage = side.gitStage {
        text = await conflictStageText(stage: stage, side: side, path: entry.path, in: repository)
      } else {
        text = workingTreeConflictText(path: entry.path, side: side, in: repository)
      }
      previews.append(ConflictPreview(side: side, text: text))
    }
    return previews
  }

  func interactiveRebasePlan(in repository: GitRepository, count: Int = 10) async throws -> InteractiveRebasePlan {
    let format = "%H%x1f%h%x1f%s"
    let output = try await git([
      "log",
      "--reverse",
      "--pretty=format:\(format)",
      "-n",
      "\(count)"
    ], in: repository.url)

    let items = output.stdout
      .split(separator: "\n", omittingEmptySubsequences: true)
      .compactMap { line -> InteractiveRebaseItem? in
        let parts = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 3 else { return nil }
        return InteractiveRebaseItem(action: .pick, hash: parts[0], shortHash: parts[1], subject: parts[2])
      }

    guard let first = items.first, items.count >= 2 else {
      throw GitClientError.notEnoughCommitsForInteractiveRebase
    }

    let upstream = try? await git(["rev-parse", "--verify", "\(first.hash)^"], in: repository.url)
    return InteractiveRebasePlan(upstream: upstream == nil ? "--root" : "\(first.hash)^", items: items)
  }

  func startInteractiveRebase(_ plan: InteractiveRebasePlan, in repository: GitRepository) async throws -> String {
    let tempDirectory = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-rebase-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDirectory) }

    let todoURL = tempDirectory.appending(path: "git-rebase-todo")
    let editorURL = tempDirectory.appending(path: "sequence-editor.sh")
    try plan.todoText.write(to: todoURL, atomically: true, encoding: .utf8)
    try """
    #!/bin/sh
    cp "$BONSAI_REBASE_TODO" "$1"
    """.write(to: editorURL, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: editorURL.path(percentEncoded: false))

    let output = try await git(
      ["rebase", "-i", plan.upstream],
      in: repository.url,
      environment: [
        "GIT_SEQUENCE_EDITOR": editorURL.path(percentEncoded: false),
        "BONSAI_REBASE_TODO": todoURL.path(percentEncoded: false)
      ]
    )
    return output.combinedOutput
  }

  func reflog(in repository: GitRepository) async throws -> String {
    try await runRaw(["reflog", "--date=iso"], in: repository)
  }

  func reflogEntries(in repository: GitRepository) async throws -> [GitReflogEntry] {
    let output = try await git([
      "log",
      "-g",
      "--pretty=format:%H%x1f%h%x1f%gd%x1f%gs%x1f%aI",
      "-n",
      "100"
    ], in: repository.url)
    return GitParsers.parseReflogEntries(output.stdout)
  }

  func blame(path: String, in repository: GitRepository) async throws -> String {
    let output = try await git(["blame", "--line-porcelain", "--", path], in: repository.url)
    return output.stdout
  }

  func blameLines(path: String, in repository: GitRepository) async throws -> [GitBlameLine] {
    let output = try await git(["blame", "--line-porcelain", "--", path], in: repository.url)
    return GitParsers.parseBlameLines(output.stdout)
  }

  func fileHistory(path: String, in repository: GitRepository) async throws -> String {
    let output = try await git([
      "log",
      "--follow",
      "--date=iso",
      "--stat",
      "--",
      path
    ], in: repository.url)
    return output.stdout
  }

  func fileHistoryEntries(path: String, in repository: GitRepository) async throws -> [GitFileHistoryEntry] {
    let format = "%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s"
    let output = try await git([
      "log",
      "--follow",
      "--date=iso-strict",
      "--pretty=format:\(format)",
      "--name-status",
      "--",
      path
    ], in: repository.url)
    return GitParsers.parseFileHistoryEntries(output.stdout)
  }

  func lineHistoryEntries(path: String, startLine: Int, endLine: Int, in repository: GitRepository) async throws -> [GitFileHistoryEntry] {
    let format = "%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s"
    let range = "\(max(startLine, 1)),\(max(endLine, startLine)):\(path)"
    let output = try await git([
      "log",
      "-L",
      range,
      "--date=iso-strict",
      "--pretty=format:\(format)"
    ], in: repository.url)
    return GitParsers.parseLineHistoryEntries(output.stdout)
  }

  func git(_ arguments: [String], in directory: URL?, standardInput: String? = nil, environment: [String: String]? = nil) async throws -> ProcessOutput {
    try await runner.run(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory, standardInput: standardInput, environment: environment)
  }

  func gitData(_ arguments: [String], in directory: URL?) async throws -> ProcessDataOutput {
    try await runner.runData(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory)
  }

  private func diffArguments(_ suffix: [String], algorithm: DiffAlgorithm, whitespaceMode: DiffWhitespaceMode) -> [String] {
    [
      "diff",
      "--no-ext-diff",
      "--no-color",
      "--find-renames",
      "--find-copies",
      "--submodule=diff",
      "--indent-heuristic",
      "--diff-algorithm=\(algorithm.rawValue)"
    ] + whitespaceMode.gitArguments + suffix
  }

  private func workingTreeConflictText(path: String, side: ConflictPreviewSide, in repository: GitRepository) -> String {
    let fileURL = repository.url.appending(path: path)
    guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
      return side.unavailableText
    }
    return limitedConflictPreview(text)
  }

  private func conflictStageText(stage: Int, side: ConflictPreviewSide, path: String, in repository: GitRepository) async -> String {
    do {
      let output = try await gitData(["show", ":\(stage):\(path)"], in: repository.url)
      guard let text = String(data: output.stdout, encoding: .utf8) else {
        return "\(side.title) is not UTF-8 text."
      }
      return limitedConflictPreview(text)
    } catch {
      return side.unavailableText
    }
  }

  private func limitedConflictPreview(_ text: String) -> String {
    let limit = 80_000
    guard text.count > limit else { return text }
    return String(text.prefix(limit)) + "\n\n[Preview truncated]"
  }

  private func commandSucceeds(_ arguments: [String], in repository: GitRepository) async -> Bool {
    (try? await git(arguments, in: repository.url)) != nil
  }

  private func configValue(_ key: String, in repository: GitRepository) async -> String? {
    guard let output = try? await git(["config", "--get", key], in: repository.url) else { return nil }
    let value = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }

  private func inProgressOperation(in repository: GitRepository) async -> GitInProgressOperationStatus {
    let rebaseMergeExists = await gitPathExists("rebase-merge", in: repository)
    let rebaseApplyExists = await gitPathExists("rebase-apply", in: repository)
    if rebaseMergeExists || rebaseApplyExists {
      return GitInProgressOperationStatus(kind: .rebase)
    }
    if await gitPathExists("MERGE_HEAD", in: repository) {
      return GitInProgressOperationStatus(kind: .merge)
    }
    if await gitPathExists("CHERRY_PICK_HEAD", in: repository) {
      return GitInProgressOperationStatus(kind: .cherryPick)
    }
    if await gitPathExists("REVERT_HEAD", in: repository) {
      return GitInProgressOperationStatus(kind: .revert)
    }
    return GitInProgressOperationStatus()
  }

  private func gitPathExists(_ path: String, in repository: GitRepository) async -> Bool {
    guard let output = try? await git(["rev-parse", "--git-path", path], in: repository.url) else { return false }
    let resolvedPath = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !resolvedPath.isEmpty else { return false }
    let url: URL
    if resolvedPath.hasPrefix("/") {
      url = URL(filePath: resolvedPath)
    } else {
      url = URL(filePath: resolvedPath, relativeTo: repository.url).standardizedFileURL
    }
    return FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
  }

  private func bisectStatus(in repository: GitRepository) async -> GitBisectStatus {
    guard let refs = try? await git([
      "for-each-ref",
      "refs/bisect",
      "--format=%(refname)%1f%(objectname)%1f%(objectname:short)"
    ], in: repository.url) else {
      return GitBisectStatus()
    }

    var status = GitBisectStatus()
    for line in refs.stdout.split(separator: "\n", omittingEmptySubsequences: true) {
      let parts = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
      guard parts.count >= 3 else { continue }
      let refName = parts[0]
      if refName == "refs/bisect/bad" {
        status.badRevision = parts[1]
      } else if refName.hasPrefix("refs/bisect/good-") {
        status.goodRevisions.append(parts[1])
      } else if refName.hasPrefix("refs/bisect/skip-") {
        status.skippedRevisions.append(parts[1])
      }
    }

    status.active = status.badRevision != nil || !status.goodRevisions.isEmpty || !status.skippedRevisions.isEmpty
    guard status.active else { return status }

    if let head = try? await git(["rev-parse", "HEAD"], in: repository.url),
       let shortHead = try? await git(["rev-parse", "--short", "HEAD"], in: repository.url) {
      status.currentHash = head.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
      status.currentShortHash = shortHead.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    status.goodRevisions.sort()
    status.skippedRevisions.sort()
    return status
  }

  private func lfsFiles(in repository: GitRepository) async -> [GitLFSFile] {
    guard let output = try? await git(["lfs", "ls-files"], in: repository.url) else { return [] }
    return GitParsers.parseLFSFiles(output.stdout)
  }
}

enum GitClientError: LocalizedError {
  case notEnoughCommitsForInteractiveRebase
  case commitNotFound(String)
  case invalidRemoteBranch(String)
  case invalidBranchUpstream(String)

  var errorDescription: String? {
    switch self {
    case .notEnoughCommitsForInteractiveRebase:
      return "At least two commits are required to start an interactive rebase."
    case .commitNotFound(let revision):
      return "Could not find commit \(revision)."
    case .invalidRemoteBranch(let branch):
      return "\(branch) is not a remote branch."
    case .invalidBranchUpstream(let branch):
      return "\(branch) does not have a usable upstream."
    }
  }
}

private extension GitRepository {
  var url: URL { URL(filePath: path, directoryHint: .isDirectory) }
}

private extension ProcessOutput {
  var combinedOutput: String {
    [stdout, stderr]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }
}
