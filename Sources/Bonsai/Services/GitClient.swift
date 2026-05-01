import Foundation

struct GitClient {
  private let runner = ProcessRunner()
  private let gitExecutable = "/usr/bin/env"

  func validateRepository(at url: URL) async throws {
    _ = try await git(["rev-parse", "--show-toplevel"], in: url)
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

  func diffForWorkingTreeFile(_ entry: GitStatusEntry, staged: Bool, in repository: GitRepository) async throws -> String {
    let args = staged
      ? ["diff", "--cached", "--", entry.path]
      : ["diff", "--", entry.path]
    let output = try await git(args, in: repository.url)
    return output.stdout
  }

  func diffForCommitFile(_ file: GitChangedFile, commit: GitCommit, in repository: GitRepository) async throws -> String {
    let output = try await git(["show", "--format=", "--find-renames", "\(commit.hash)", "--", file.path], in: repository.url)
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

  func git(_ arguments: [String], in directory: URL?) async throws -> ProcessOutput {
    try await runner.run(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory)
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
