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
      submodules: submodules
    )
  }

  func status(in repository: GitRepository) async throws -> [GitStatusEntry] {
    let output = try await git(["status", "--porcelain=v1"], in: repository.url)
    return GitParsers.parseStatus(output.stdout)
  }

  func commits(in repository: GitRepository) async throws -> [GitCommit] {
    let format = "%H%x1f%h%x1f%an%x1f%ae%x1f%ad%x1f%s%x1f%D"
    let output = try await git([
      "log",
      "--date=iso-strict",
      "--decorate=short",
      "--pretty=format:\(format)",
      "-n",
      "300"
    ], in: repository.url)
    return GitParsers.parseCommits(output.stdout)
  }

  func refs(in repository: GitRepository) async throws -> [GitRef] {
    let format = "%(refname)%1f%(objectname:short)%1f%(upstream:short)%1f%(HEAD)"
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

  func stashes(in repository: GitRepository) async throws -> [GitStash] {
    let output = try? await git(["stash", "list"], in: repository.url)
    return GitParsers.parseStashes(output?.stdout ?? "")
  }

  func submodules(in repository: GitRepository) async throws -> [GitSubmodule] {
    let output = try? await git(["submodule", "status", "--recursive"], in: repository.url)
    return GitParsers.parseSubmodules(output?.stdout ?? "")
  }

  func changedFiles(in repository: GitRepository, commit: GitCommit?) async throws -> [GitChangedFile] {
    guard let commit else { return [] }
    let output = try await git(["show", "--format=", "--name-status", commit.hash], in: repository.url)
    return GitParsers.parseChangedFiles(output.stdout)
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

  func stage(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    let output = try await git(["add", "--", entry.path], in: repository.url)
    return output.combinedOutput
  }

  func unstage(_ entry: GitStatusEntry, in repository: GitRepository) async throws -> String {
    let output = try await git(["restore", "--staged", "--", entry.path], in: repository.url)
    return output.combinedOutput
  }

  func stageHunk(_ hunk: DiffHunk, in repository: GitRepository) async throws -> String {
    let output = try await git(["apply", "--cached"], in: repository.url, standardInput: hunk.patch)
    return output.combinedOutput
  }

  func unstageHunk(_ hunk: DiffHunk, in repository: GitRepository) async throws -> String {
    let output = try await git(["apply", "--cached", "--reverse"], in: repository.url, standardInput: hunk.patch)
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

  func deleteBranch(_ name: String, force: Bool, in repository: GitRepository) async throws -> String {
    try await runRaw(["branch", force ? "-D" : "-d", name], in: repository)
  }

  func deleteTag(_ name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(["tag", "-d", name], in: repository)
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

    return InteractiveRebasePlan(upstream: "\(first.hash)^", items: items)
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

  func blame(path: String, in repository: GitRepository) async throws -> String {
    let output = try await git(["blame", "--line-porcelain", "--", path], in: repository.url)
    return output.stdout
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

  func git(_ arguments: [String], in directory: URL?, standardInput: String? = nil, environment: [String: String]? = nil) async throws -> ProcessOutput {
    try await runner.run(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory, standardInput: standardInput, environment: environment)
  }

  private func diffArguments(_ suffix: [String], algorithm: DiffAlgorithm) -> [String] {
    [
      "diff",
      "--find-renames",
      "--find-copies",
      "--submodule=diff",
      "--indent-heuristic",
      "--diff-algorithm=\(algorithm.rawValue)"
    ] + suffix
  }
}

enum GitClientError: LocalizedError {
  case notEnoughCommitsForInteractiveRebase

  var errorDescription: String? {
    switch self {
    case .notEnoughCommitsForInteractiveRebase:
      return "At least two commits are required to start an interactive rebase."
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
