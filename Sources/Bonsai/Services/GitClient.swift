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
      integrations: integrations
    )
  }

  func status(in repository: GitRepository) async throws -> [GitStatusEntry] {
    let output = try await git(["status", "--porcelain=v1"], in: repository.url)
    return GitParsers.parseStatus(output.stdout)
  }

  func commits(in repository: GitRepository) async throws -> [GitCommit] {
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
    try await runRaw(["remote", "add", name, url], in: repository)
  }

  func setRemoteURL(name: String, url: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["remote", "set-url", name, url], in: repository)
  }

  func removeRemote(name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["remote", "remove", name], in: repository)
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
      gitFlowDevelopBranch: developBranch
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

  func diffForWorkingTreeFile(_ entry: GitStatusEntry, staged: Bool, algorithm: DiffAlgorithm, in repository: GitRepository) async throws -> String {
    let args = staged
      ? diffArguments(["--cached", "--", entry.path], algorithm: algorithm)
      : diffArguments(["--", entry.path], algorithm: algorithm)
    let output = try await git(args, in: repository.url)
    return output.stdout
  }

  func diffForCommitFile(_ file: GitChangedFile, commit: GitCommit, algorithm: DiffAlgorithm, in repository: GitRepository) async throws -> String {
    let output = try await git([
      "show",
      "--format=",
      "--no-ext-diff",
      "--no-color",
      "--find-renames",
      "--find-copies",
      "--diff-algorithm=\(algorithm.rawValue)",
      "--indent-heuristic",
      "\(commit.hash)",
      "--",
      file.path
    ], in: repository.url)
    return output.stdout
  }

  func diffForStashFile(_ file: GitChangedFile, stash: GitStash, algorithm: DiffAlgorithm, in repository: GitRepository) async throws -> String {
    let output = try await git(diffArguments(["\(stash.index)^1", stash.index, "--", file.path], algorithm: algorithm), in: repository.url)
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

  func stage(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    let output = try await git(["add", "--", entry.path], in: repository.url)
    return output.combinedOutput
  }

  func unstage(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    let output = try await git(["restore", "--staged", "--", entry.path], in: repository.url)
    return output.combinedOutput
  }

  func discard(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    if entry.isUntracked {
      return try await runRaw(["clean", "-f", "--", entry.path], in: repository)
    }

    var outputs: [String] = []
    if entry.isStaged {
      outputs.append(try await unstage(entry, in: repository))
    }
    outputs.append(try await runRaw(["restore", "--worktree", "--", entry.path], in: repository))
    return outputs.filter { !$0.isEmpty }.joined(separator: "\n")
  }

  func stageHunk(_ hunk: DiffHunk, in repository: GitRepository) async throws -> String {
    let output = try await git(["apply", "--cached"], in: repository.url, standardInput: hunk.patch)
    return output.combinedOutput
  }

  func unstageHunk(_ hunk: DiffHunk, in repository: GitRepository) async throws -> String {
    let output = try await git(["apply", "--cached", "--reverse"], in: repository.url, standardInput: hunk.patch)
    return output.combinedOutput
  }

  func stageLineChange(_ change: DiffLineChange, in repository: GitRepository) async throws -> String {
    let output = try await git(["apply", "--cached", "--unidiff-zero"], in: repository.url, standardInput: change.patch)
    return output.combinedOutput
  }

  func unstageLineChange(_ change: DiffLineChange, in repository: GitRepository) async throws -> String {
    let output = try await git(["apply", "--cached", "--reverse", "--unidiff-zero"], in: repository.url, standardInput: change.patch)
    return output.combinedOutput
  }

  func applyPatch(_ patch: String, in repository: GitRepository) async throws -> String {
    let output = try await git(["apply"], in: repository.url, standardInput: patch)
    return output.combinedOutput
  }

  func commit(message: String, amend: Bool, sign: Bool, in repository: GitRepository) async throws -> String {
    var args = ["commit", "-m", message]
    if amend { args.append("--amend") }
    if sign { args.append("-S") }
    let output = try await git(args, in: repository.url)
    return output.combinedOutput
  }

  func runAction(_ action: RepositoryAction, in repository: GitRepository) async throws -> String {
    let command: [String]
    switch action {
    case .fetch:
      command = ["fetch", "--all", "--prune"]
    case .pull:
      command = ["pull", "--ff-only"]
    case .push:
      command = ["push"]
    }
    let output = try await git(command, in: repository.url)
    return output.combinedOutput
  }

  func runRaw(_ arguments: [String], in repository: GitRepository) async throws -> String {
    let output = try await git(arguments, in: repository.url)
    return output.combinedOutput
  }

  func createBranch(named name: String, startPoint: String?, in repository: GitRepository) async throws -> String {
    var args = ["branch", name]
    if let startPoint, !startPoint.isEmpty {
      args.append(startPoint)
    }
    return try await runRaw(args, in: repository)
  }

  func createTag(named name: String, target: String?, in repository: GitRepository) async throws -> String {
    var args = ["tag", name]
    if let target, !target.isEmpty {
      args.append(target)
    }
    return try await runRaw(args, in: repository)
  }

  func checkout(_ ref: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["checkout", ref], in: repository)
  }

  func reset(to commit: GitCommit, mode: ResetMode, in repository: GitRepository) async throws -> String {
    try await runRaw(["reset", mode.flag, commit.hash], in: repository)
  }

  func reset(to entry: GitReflogEntry, mode: ResetMode, in repository: GitRepository) async throws -> String {
    try await runRaw(["reset", mode.flag, entry.hash], in: repository)
  }

  func deleteBranch(_ name: String, force: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(["branch", force ? "-D" : "-d", name], in: repository)
  }

  func deleteTag(_ name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["tag", "-d", name], in: repository)
  }

  func createWorktree(at path: String, startPoint: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["worktree", "add", "--detach", path, startPoint], in: repository)
  }

  func removeWorktree(_ worktree: GitWorktree, in repository: GitRepository) async throws -> String {
    try await runRaw(["worktree", "remove", worktree.path], in: repository)
  }

  func stashPush(message: String?, in repository: GitRepository) async throws -> String {
    var args = ["stash", "push"]
    if let message, !message.isEmpty {
      args += ["-m", message]
    }
    return try await runRaw(args, in: repository)
  }

  func stashApply(_ stash: GitStash, pop: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(["stash", pop ? "pop" : "apply", stash.index], in: repository)
  }

  func stashDrop(_ stash: GitStash, in repository: GitRepository) async throws -> String {
    try await runRaw(["stash", "drop", stash.index], in: repository)
  }

  func updateSubmodules(in repository: GitRepository) async throws -> String {
    try await runRaw(["submodule", "update", "--init", "--recursive"], in: repository)
  }

  func updateSubmodule(_ submodule: GitSubmodule, in repository: GitRepository) async throws -> String {
    try await runRaw(["submodule", "update", "--init", "--recursive", "--", submodule.path], in: repository)
  }

  func lfsPull(in repository: GitRepository) async throws -> String {
    try await runRaw(["lfs", "pull"], in: repository)
  }

  func lfsLock(path: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["lfs", "lock", path], in: repository)
  }

  func lfsUnlock(path: String, force: Bool, in repository: GitRepository) async throws -> String {
    var args = ["lfs", "unlock"]
    if force {
      args.append("--force")
    }
    args.append(path)
    return try await runRaw(args, in: repository)
  }

  func setCommitSigning(_ enabled: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(["config", "commit.gpgsign", enabled ? "true" : "false"], in: repository)
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

  func git(_ arguments: [String], in directory: URL?, standardInput: String? = nil, environment: [String: String]? = nil) async throws -> ProcessOutput {
    try await runner.run(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory, standardInput: standardInput, environment: environment)
  }

  func gitData(_ arguments: [String], in directory: URL?) async throws -> ProcessDataOutput {
    try await runner.runData(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory)
  }

  private func diffArguments(_ suffix: [String], algorithm: DiffAlgorithm) -> [String] {
    [
      "diff",
      "--no-ext-diff",
      "--no-color",
      "--find-renames",
      "--find-copies",
      "--submodule=diff",
      "--indent-heuristic",
      "--diff-algorithm=\(algorithm.rawValue)"
    ] + suffix
  }

  private func commandSucceeds(_ arguments: [String], in repository: GitRepository) async -> Bool {
    (try? await git(arguments, in: repository.url)) != nil
  }

  private func configValue(_ key: String, in repository: GitRepository) async -> String? {
    guard let output = try? await git(["config", "--get", key], in: repository.url) else { return nil }
    let value = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }

  private func lfsFiles(in repository: GitRepository) async -> [GitLFSFile] {
    guard let output = try? await git(["lfs", "ls-files"], in: repository.url) else { return [] }
    return GitParsers.parseLFSFiles(output.stdout)
  }
}

enum GitClientError: LocalizedError {
  case notEnoughCommitsForInteractiveRebase
  case commitNotFound(String)

  var errorDescription: String? {
    switch self {
    case .notEnoughCommitsForInteractiveRebase:
      return "At least two commits are required to start an interactive rebase."
    case .commitNotFound(let revision):
      return "Could not find commit \(revision)."
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
