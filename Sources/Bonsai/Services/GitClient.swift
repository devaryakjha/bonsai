import Foundation

struct GitClient {
  private let runner = ProcessRunner()
  private let gitExecutable = "/usr/bin/env"

  func validateRepository(at url: URL) async throws {
    _ = try await git(Self.validateRepositoryArguments(), in: url)
  }

  static func validateRepositoryArguments() -> [String] {
    ["rev-parse", "--show-toplevel"]
  }

  func cloneRepository(from remoteURL: String, to destination: URL) async throws -> String {
    let parent = destination.deletingLastPathComponent()
    let output = try await git(Self.cloneRepositoryArguments(remoteURL: remoteURL, destination: destination), in: parent)
    return output.combinedOutput
  }

  static func cloneRepositoryArguments(remoteURL: String, destination: URL) -> [String] {
    ["clone", remoteURL, destination.path(percentEncoded: false)]
  }

  func initializeRepository(at destination: URL) async throws -> String {
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    let output = try await git(Self.initializeRepositoryArguments(), in: destination)
    return output.combinedOutput
  }

  static func initializeRepositoryArguments() -> [String] {
    ["init"]
  }

  func repositoryBenchmark(in repository: GitRepository) async throws -> RepositoryBenchmarkReport {
    let status = try await measuredGit(
      Self.repositoryBenchmarkStatusArguments(),
      title: "Status scan",
      detail: "Working tree",
      in: repository
    )
    let commits = try await measuredGit(
      Self.repositoryBenchmarkCommitCountArguments(),
      title: "Commit count",
      detail: "All refs",
      in: repository
    )
    let refs = try await measuredGit(
      Self.repositoryBenchmarkRefsArguments(),
      title: "Reference scan",
      detail: "Branches and tags",
      in: repository
    )
    let files = try await measuredGit(
      Self.repositoryBenchmarkTrackedFilesArguments(),
      title: "Tracked file scan",
      detail: "Index",
      in: repository
    )
    let objects = try await measuredGit(
      Self.repositoryBenchmarkObjectStatsArguments(),
      title: "Object database scan",
      detail: "Loose and packed objects",
      in: repository
    )
    let objectStats = Self.parseRepositoryObjectStats(objects.stdout)
    let changedCount = status.stdout.split(separator: "\n", omittingEmptySubsequences: true).count
    let commitCount = Int(commits.stdout.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    let refCount = refs.stdout.split(separator: "\n", omittingEmptySubsequences: true).count
    let trackedFileCount = Self.countNULTerminatedRecords(files.stdout)

    return RepositoryBenchmarkReport(
      repository: repository,
      generatedAt: Date(),
      metrics: [
        RepositoryBenchmarkMetric(
          title: "Commits",
          value: commitCount.formatted(),
          detail: "Reachable from all refs",
          systemImage: "point.3.connected.trianglepath.dotted"
        ),
        RepositoryBenchmarkMetric(
          title: "References",
          value: refCount.formatted(),
          detail: "Branches and tags",
          systemImage: "tag"
        ),
        RepositoryBenchmarkMetric(
          title: "Tracked files",
          value: trackedFileCount.formatted(),
          detail: "Index entries",
          systemImage: "doc.text"
        ),
        RepositoryBenchmarkMetric(
          title: "Working tree changes",
          value: changedCount.formatted(),
          detail: "Porcelain status entries",
          systemImage: "plusminus"
        ),
        RepositoryBenchmarkMetric(
          title: "Loose objects",
          value: objectStats.looseObjects.formatted(),
          detail: objectStats.looseSize,
          systemImage: "shippingbox"
        ),
        RepositoryBenchmarkMetric(
          title: "Packed objects",
          value: objectStats.packedObjects.formatted(),
          detail: objectStats.packSize,
          systemImage: "archivebox"
        )
      ],
      timings: [
        status.timing,
        commits.timing,
        refs.timing,
        files.timing,
        objects.timing
      ]
    )
  }

  static func repositoryBenchmarkStatusArguments() -> [String] {
    statusArguments()
  }

  static func repositoryBenchmarkCommitCountArguments() -> [String] {
    ["rev-list", "--count", "--all"]
  }

  static func repositoryBenchmarkRefsArguments() -> [String] {
    ["for-each-ref", "--format=%(refname)"]
  }

  static func repositoryBenchmarkTrackedFilesArguments() -> [String] {
    ["ls-files", "-z"]
  }

  static func repositoryBenchmarkObjectStatsArguments() -> [String] {
    ["count-objects", "-vH"]
  }

  static func parseRepositoryObjectStats(_ output: String) -> RepositoryObjectStats {
    var values: [String: String] = [:]
    for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
      let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
      guard parts.count == 2 else { continue }
      values[String(parts[0])] = parts[1].trimmingCharacters(in: .whitespaces)
    }

    return RepositoryObjectStats(
      looseObjects: Int(values["count"] ?? "") ?? 0,
      looseSize: values["size"] ?? RepositoryObjectStats.empty.looseSize,
      packedObjects: Int(values["in-pack"] ?? "") ?? 0,
      packSize: values["size-pack"] ?? RepositoryObjectStats.empty.packSize
    )
  }

  static func countNULTerminatedRecords(_ output: String) -> Int {
    output.split(separator: "\0", omittingEmptySubsequences: true).count
  }

  func repositoryTreemap(in repository: GitRepository) async throws -> RepositoryTreemapReport {
    let output = try await git(Self.repositoryTreemapArguments(), in: repository.url)
    let files = Self.parseRepositoryTreemapFiles(output.stdout)
    return RepositoryTreemapReport(
      repository: repository,
      generatedAt: Date(),
      tiles: Self.repositoryTreemapTiles(files: files)
    )
  }

  static func repositoryTreemapArguments() -> [String] {
    ["ls-tree", "-r", "-l", "-z", "HEAD"]
  }

  static func parseRepositoryTreemapFiles(_ output: String) -> [RepositoryTreemapFile] {
    output.split(separator: "\0", omittingEmptySubsequences: true).compactMap { record in
      guard let tabIndex = record.firstIndex(of: "\t") else { return nil }
      let metadata = record[..<tabIndex]
        .split(separator: " ", omittingEmptySubsequences: true)
      guard metadata.count >= 4 else { return nil }
      guard let bytes = Int(metadata[3]), bytes >= 0 else { return nil }
      let path = String(record[record.index(after: tabIndex)...])
      guard !path.isEmpty else { return nil }
      return RepositoryTreemapFile(path: path, bytes: bytes)
    }
  }

  static func repositoryTreemapTiles(files: [RepositoryTreemapFile], maxTiles: Int = 12) -> [RepositoryTreemapTile] {
    guard !files.isEmpty else { return [] }

    var aggregate: [String: (title: String, path: String, bytes: Int, fileCount: Int)] = [:]
    for file in files {
      let component = file.path.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? file.path
      let isDirectory = file.path.contains("/")
      let key = isDirectory ? "\(component)/" : component
      let title = isDirectory ? component : file.path
      var value = aggregate[key] ?? (title: title, path: key, bytes: 0, fileCount: 0)
      value.bytes += file.bytes
      value.fileCount += 1
      aggregate[key] = value
    }

    let sorted = aggregate.values
      .map { RepositoryTreemapTile(title: $0.title, path: $0.path, bytes: $0.bytes, fileCount: $0.fileCount) }
      .sorted {
        if $0.bytes == $1.bytes {
          return $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
        return $0.bytes > $1.bytes
      }

    guard sorted.count > maxTiles, maxTiles > 1 else {
      return sorted
    }

    let visible = Array(sorted.prefix(maxTiles - 1))
    let hidden = sorted.dropFirst(maxTiles - 1)
    let other = RepositoryTreemapTile(
      title: "Other",
      path: "__other__",
      bytes: hidden.reduce(0) { $0 + $1.bytes },
      fileCount: hidden.reduce(0) { $0 + $1.fileCount }
    )
    return visible + [other]
  }

  func snapshot(
    for repository: GitRepository,
    selectedCommit: GitCommit?,
    includeIgnoredFiles: Bool = false
  ) async throws -> RepositorySnapshot {
    async let status = status(in: repository, includeIgnoredFiles: includeIgnoredFiles)
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

  func status(in repository: GitRepository, includeIgnoredFiles: Bool = false) async throws -> [GitStatusEntry] {
    let output = try await git(Self.statusArguments(includeIgnoredFiles: includeIgnoredFiles), in: repository.url)
    return GitParsers.parseStatus(output.stdout)
  }

  static func statusArguments(includeIgnoredFiles: Bool = false) -> [String] {
    var arguments = ["status", "--porcelain=v1", "--untracked-files=all"]
    if includeIgnoredFiles {
      arguments.append("--ignored=matching")
    }
    return arguments
  }

  func commits(in repository: GitRepository) async throws -> [GitCommit] {
    guard await commandSucceeds(Self.headVerificationArguments(), in: repository) else {
      return []
    }

    let output = try await git(Self.commitListArguments(limit: 300), in: repository.url)
    return GitParsers.parseCommits(output.stdout)
  }

  static func headVerificationArguments() -> [String] {
    ["rev-parse", "--verify", "HEAD"]
  }

  static func commitListArguments(limit: Int) -> [String] {
    let format = "%x1f%H%x1f%h%x1f%an%x1f%ae%x1f%ad%x1f%s%x1f%D"
    return [
      "log",
      "--graph",
      "--date=iso-strict",
      "--decorate=short",
      "--pretty=format:\(format)",
      "-n",
      "\(limit)"
    ]
  }

  func commit(revision: String, in repository: GitRepository) async throws -> GitCommit {
    let output = try await git(Self.commitArguments(revision: revision), in: repository.url)
    guard let commit = GitParsers.parseCommits(output.stdout).first else {
      throw GitClientError.commitNotFound(revision)
    }
    return commit
  }

  static func commitArguments(revision: String) -> [String] {
    let format = "%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s%x1f%D"
    return [
      "log",
      "--date=iso-strict",
      "--decorate=short",
      "--pretty=format:\(format)",
      "-n",
      "1",
      revision
    ]
  }

  func refs(in repository: GitRepository) async throws -> [GitRef] {
    let output = try await git(Self.refsArguments(), in: repository.url)
    return GitParsers.parseRefs(output.stdout)
  }

  static func refsArguments() -> [String] {
    let format = "%(refname)%1f%(objectname:short)%1f%(upstream:short)%1f%(HEAD)%1f%(upstream:track)"
    return [
      "for-each-ref",
      "refs/heads",
      "refs/remotes",
      "refs/tags",
      "--format=\(format)"
    ]
  }

  func remotes(in repository: GitRepository) async throws -> [GitRemote] {
    let output = try await git(Self.remotesArguments(), in: repository.url)
    return GitParsers.parseRemotes(output.stdout)
  }

  static func remotesArguments() -> [String] {
    ["remote", "-v"]
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
    let output = try? await git(Self.stashListArguments(), in: repository.url)
    return GitParsers.parseStashes(output?.stdout ?? "")
  }

  static func stashListArguments() -> [String] {
    ["stash", "list"]
  }

  func submodules(in repository: GitRepository) async throws -> [GitSubmodule] {
    let output = try? await git(Self.submoduleStatusArguments(), in: repository.url)
    return GitParsers.parseSubmodules(output?.stdout ?? "")
  }

  static func submoduleStatusArguments() -> [String] {
    ["submodule", "status", "--recursive"]
  }

  func worktrees(in repository: GitRepository) async throws -> [GitWorktree] {
    let output = try? await git(Self.worktreeListArguments(), in: repository.url)
    return GitParsers.parseWorktrees(output?.stdout ?? "")
  }

  static func worktreeListArguments() -> [String] {
    ["worktree", "list", "--porcelain"]
  }

  func integrations(in repository: GitRepository) async -> GitIntegrationStatus {
    async let lfsAvailable = commandSucceeds(Self.lfsVersionArguments(), in: repository)
    async let gitFlowAvailable = commandSucceeds(Self.gitFlowVersionArguments(), in: repository)
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

  static func lfsVersionArguments() -> [String] {
    ["lfs", "version"]
  }

  static func gitFlowVersionArguments() -> [String] {
    ["flow", "version"]
  }

  func changedFiles(in repository: GitRepository, commit: GitCommit?) async throws -> [GitChangedFile] {
    guard let commit else { return [] }
    let output = try await git(Self.changedFilesArguments(commit: commit), in: repository.url)
    return GitParsers.parseChangedFiles(output.stdout)
  }

  static func changedFilesArguments(commit: GitCommit) -> [String] {
    ["show", "--format=", "--name-status", commit.hash]
  }

  func changedFiles(in repository: GitRepository, stash: GitStash?) async throws -> [GitChangedFile] {
    guard let stash else { return [] }
    let output = try await git(Self.changedFilesArguments(stash: stash), in: repository.url)
    return GitParsers.parseChangedFiles(output.stdout)
  }

  static func changedFilesArguments(stash: GitStash) -> [String] {
    ["stash", "show", "--name-status", stash.index]
  }

  func treeEntries(in repository: GitRepository, commit: GitCommit?, path: String = "") async throws -> [GitTreeEntry] {
    guard let commit else { return [] }
    let output = try await git(Self.treeEntriesArguments(commit: commit, path: path), in: repository.url)
    return GitParsers.parseTreeEntries(output.stdout, basePath: path)
  }

  static func treeEntriesArguments(commit: GitCommit, path: String = "") -> [String] {
    let target = path.isEmpty ? commit.hash : "\(commit.hash):\(path)"
    return ["ls-tree", "-z", target]
  }

  func blobText(path: String, commit: GitCommit, in repository: GitRepository) async throws -> String {
    let output = try await gitData(Self.blobTextArguments(path: path, commit: commit), in: repository.url)
    if let text = String(data: output.stdout, encoding: .utf8) {
      return text
    }
    return "Binary file preview is not available for \(path)."
  }

  static func blobTextArguments(path: String, commit: GitCommit) -> [String] {
    ["show", "\(commit.hash):\(path)"]
  }

  func diffForWorkingTreeFile(
    _ entry: GitStatusEntry,
    staged: Bool,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let args = Self.diffForWorkingTreeFileArguments(
      entry,
      staged: staged,
      algorithm: algorithm,
      whitespaceMode: whitespaceMode
    )
    let output = try await git(args, in: repository.url)
    return output.stdout
  }

  static func diffForWorkingTreeFileArguments(
    _ entry: GitStatusEntry,
    staged: Bool,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode
  ) -> [String] {
    let suffix = staged ? ["--cached", "--", entry.path] : ["--", entry.path]
    return diffArguments(suffix, algorithm: algorithm, whitespaceMode: whitespaceMode)
  }

  func conflictResolvedDiff(
    _ entry: GitStatusEntry,
    base: ConflictDiffBase,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let output = try await git(
      Self.conflictResolvedDiffArguments(
        entry,
        base: base,
        algorithm: algorithm,
        whitespaceMode: whitespaceMode
      ),
      in: repository.url
    )
    return output.stdout
  }

  static func conflictResolvedDiffArguments(
    _ entry: GitStatusEntry,
    base: ConflictDiffBase,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode
  ) -> [String] {
    diffArguments([base.gitArgument, "--", entry.path], algorithm: algorithm, whitespaceMode: whitespaceMode)
  }

  func diffForCommitFile(
    _ file: GitChangedFile,
    commit: GitCommit,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let output = try await git(
      Self.diffForCommitFileArguments(file, commit: commit, algorithm: algorithm, whitespaceMode: whitespaceMode),
      in: repository.url
    )
    return output.stdout
  }

  static func diffForCommitFileArguments(
    _ file: GitChangedFile,
    commit: GitCommit,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode
  ) -> [String] {
    [
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
    ]
  }

  func commitPatch(
    _ commit: GitCommit,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let output = try await git(
      Self.commitPatchArguments(commit, algorithm: algorithm, whitespaceMode: whitespaceMode),
      in: repository.url
    )
    return output.stdout
  }

  static func commitPatchArguments(
    _ commit: GitCommit,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode
  ) -> [String] {
    [
      "show",
      "--format=",
      "--no-ext-diff",
      "--no-color",
      "--find-renames",
      "--find-copies",
      "--submodule=diff",
      "--indent-heuristic",
      "--diff-algorithm=\(algorithm.rawValue)",
    ] + whitespaceMode.gitArguments + [
      commit.hash
    ]
  }

  func diffForStashFile(
    _ file: GitChangedFile,
    stash: GitStash,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode,
    in repository: GitRepository
  ) async throws -> String {
    let output = try await git(
      Self.diffForStashFileArguments(file, stash: stash, algorithm: algorithm, whitespaceMode: whitespaceMode),
      in: repository.url
    )
    return output.stdout
  }

  static func diffForStashFileArguments(
    _ file: GitChangedFile,
    stash: GitStash,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode
  ) -> [String] {
    diffArguments(["\(stash.index)^1", stash.index, "--", file.path], algorithm: algorithm, whitespaceMode: whitespaceMode)
  }

  func imageDiffForWorkingTreeFile(_ entry: GitStatusEntry, in repository: GitRepository) async -> ImageDiffSnapshot {
    let oldPath = entry.originalPath ?? entry.path
    let oldData = entry.isUntracked ? nil : try? await gitData(Self.workingTreeImageOldArguments(path: oldPath), in: repository.url).stdout
    let newData: Data?
    if entry.isStaged {
      newData = try? await gitData(Self.workingTreeImageIndexArguments(path: entry.path), in: repository.url).stdout
    } else if entry.kind == .deleted {
      newData = nil
    } else {
      newData = try? Data(contentsOf: repository.url.appending(path: entry.path))
    }
    return ImageDiffSnapshot(path: entry.path, oldData: oldData, newData: newData)
  }

  static func workingTreeImageOldArguments(path: String) -> [String] {
    ["show", "HEAD:\(path)"]
  }

  static func workingTreeImageIndexArguments(path: String) -> [String] {
    ["show", ":\(path)"]
  }

  func imageDiffForCommitFile(_ file: GitChangedFile, commit: GitCommit, in repository: GitRepository) async -> ImageDiffSnapshot {
    let oldData = try? await gitData(Self.commitImageOldArguments(file: file, commit: commit), in: repository.url).stdout
    let newData = file.status.hasPrefix("D") ? nil : try? await gitData(Self.commitImageNewArguments(file: file, commit: commit), in: repository.url).stdout
    return ImageDiffSnapshot(path: file.path, oldData: oldData, newData: newData)
  }

  static func commitImageOldArguments(file: GitChangedFile, commit: GitCommit) -> [String] {
    let oldPath = file.oldPath ?? file.path
    return ["show", "\(commit.hash)^:\(oldPath)"]
  }

  static func commitImageNewArguments(file: GitChangedFile, commit: GitCommit) -> [String] {
    ["show", "\(commit.hash):\(file.path)"]
  }

  func imageDiffForStashFile(_ file: GitChangedFile, stash: GitStash, in repository: GitRepository) async -> ImageDiffSnapshot {
    let oldData = file.status.hasPrefix("A") ? nil : try? await gitData(Self.stashImageOldArguments(file: file, stash: stash), in: repository.url).stdout
    let newData = file.status.hasPrefix("D") ? nil : try? await gitData(Self.stashImageNewArguments(file: file, stash: stash), in: repository.url).stdout
    return ImageDiffSnapshot(path: file.path, oldData: oldData, newData: newData)
  }

  static func stashImageOldArguments(file: GitChangedFile, stash: GitStash) -> [String] {
    let oldPath = file.oldPath ?? file.path
    return ["show", "\(stash.index)^1:\(oldPath)"]
  }

  static func stashImageNewArguments(file: GitChangedFile, stash: GitStash) -> [String] {
    ["show", "\(stash.index):\(file.path)"]
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
    let hasHead = await commandSucceeds(Self.headVerificationArguments(), in: repository)
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

  func discardUnstaged(_ entries: [GitStatusEntry], in repository: GitRepository) async throws -> String {
    let tracked = entries.filter { !$0.isUntracked }
    let untracked = entries.filter(\.isUntracked)
    guard !tracked.isEmpty || !untracked.isEmpty else { return "" }

    var outputs: [String] = []
    if !tracked.isEmpty {
      outputs.append(try await runRaw(Self.discardWorktreeArguments(tracked), in: repository))
    }
    if !untracked.isEmpty {
      outputs.append(try await runRaw(Self.discardUntrackedArguments(untracked), in: repository))
    }
    return outputs.filter { !$0.isEmpty }.joined(separator: "\n")
  }

  static func discardUntrackedArguments(_ entry: GitStatusEntry) -> [String] {
    ["clean", "-f", "--", entry.path]
  }

  static func discardUntrackedArguments(_ entries: [GitStatusEntry]) -> [String] {
    ["clean", "-f", "--"] + entries.map(\.path)
  }

  static func discardWorktreeArguments(_ entry: GitStatusEntry) -> [String] {
    ["restore", "--worktree", "--", entry.path]
  }

  static func discardWorktreeArguments(_ entries: [GitStatusEntry]) -> [String] {
    ["restore", "--worktree", "--"] + entries.map(\.path)
  }

  func cleanIgnored(_ entries: [GitStatusEntry], in repository: GitRepository) async throws -> String {
    guard !entries.isEmpty else { return "" }
    return try await runRaw(Self.cleanIgnoredArguments(entries), in: repository)
  }

  static func cleanIgnoredArguments(_ entries: [GitStatusEntry]) -> [String] {
    ["clean", "-f", "-X", "-d", "--"] + entries.map(\.path)
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

  func applyGitIgnoreTemplate(_ template: GitIgnoreTemplate, in repository: GitRepository) throws -> String {
    let ignoreURL = repository.url.appending(path: ".gitignore")
    let existing = (try? String(contentsOf: ignoreURL, encoding: .utf8)) ?? ""
    let existingPatterns = Set(
      existing
        .split(separator: "\n")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    )
    let missingPatterns = template.patterns.filter { !existingPatterns.contains($0) }
    if missingPatterns.isEmpty {
      return "Already contains \(template.name) .gitignore template."
    }

    var updated = existing
    if !updated.isEmpty && !updated.hasSuffix("\n") {
      updated.append("\n")
    }
    if !updated.isEmpty {
      updated.append("\n")
    }
    updated.append("# \(template.name)\n")
    updated.append(missingPatterns.joined(separator: "\n"))
    updated.append("\n")
    try updated.write(to: ignoreURL, atomically: true, encoding: .utf8)
    return "Added \(template.name) .gitignore template."
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

  func runRevisionCommand(
    _ command: GitRevisionCommand,
    commit: GitCommit,
    updateRefs: Bool = false,
    in repository: GitRepository
  ) async throws -> String {
    try await runRaw(command.arguments(commitHash: commit.hash, updateRefs: updateRefs), in: repository)
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
    let object = try await git(Self.renameTagResolveArguments(oldName: oldName), in: repository.url).stdout
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let create = try await git(Self.renameTagCreateArguments(newName: newName, object: object), in: repository.url)
    let delete = try await git(Self.renameTagDeleteArguments(oldName: oldName), in: repository.url)
    return [create.combinedOutput, delete.combinedOutput]
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }

  static func renameTagResolveArguments(oldName: String) -> [String] {
    ["rev-parse", tagRefName(oldName)]
  }

  static func renameTagCreateArguments(newName: String, object: String) -> [String] {
    ["update-ref", tagRefName(newName), object, ""]
  }

  static func renameTagDeleteArguments(oldName: String) -> [String] {
    ["update-ref", "-d", tagRefName(oldName)]
  }

  private static func tagRefName(_ name: String) -> String {
    "refs/tags/\(name)"
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
    let output = try await git(Self.stashPatchArguments(stash, algorithm: algorithm, whitespaceMode: whitespaceMode), in: repository.url)
    return output.stdout
  }

  static func stashPatchArguments(
    _ stash: GitStash,
    algorithm: DiffAlgorithm,
    whitespaceMode: DiffWhitespaceMode
  ) -> [String] {
    [
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
    ]
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
    try await runRaw(Self.lfsLockArguments(path: path), in: repository)
  }

  static func lfsLockArguments(path: String) -> [String] {
    ["lfs", "lock", path]
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
    try await runRaw(Self.setCommitSigningArguments(enabled), in: repository)
  }

  static func setCommitSigningArguments(_ enabled: Bool) -> [String] {
    ["config", "commit.gpgsign", enabled ? "true" : "false"]
  }

  func runInProgressOperation(_ action: GitInProgressOperationAction, kind: GitInProgressOperationKind, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.inProgressOperationArguments(action, kind: kind), in: repository)
  }

  static func inProgressOperationArguments(_ action: GitInProgressOperationAction, kind: GitInProgressOperationKind) -> [String] {
    [kind.command, action.flag]
  }

  func startBisect(bad: String, good: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.startBisectArguments(bad: bad, good: good), in: repository)
  }

  static func startBisectArguments(bad: String, good: String) -> [String] {
    ["bisect", "start", bad, good]
  }

  func markBisect(_ mark: GitBisectMark, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.markBisectArguments(mark), in: repository)
  }

  static func markBisectArguments(_ mark: GitBisectMark) -> [String] {
    ["bisect", mark.rawValue]
  }

  func resetBisect(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.resetBisectArguments(), in: repository)
  }

  static func resetBisectArguments() -> [String] {
    ["bisect", "reset"]
  }

  func initializeGitFlow(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.initializeGitFlowArguments(), in: repository)
  }

  static func initializeGitFlowArguments() -> [String] {
    ["flow", "init", "-d"]
  }

  func startGitFlow(kind: GitFlowStartKind, name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.startGitFlowArguments(kind: kind, name: name), in: repository)
  }

  static func startGitFlowArguments(kind: GitFlowStartKind, name: String) -> [String] {
    ["flow", kind.rawValue, "start", name]
  }

  func finishGitFlow(kind: GitFlowStartKind, name: String, in repository: GitRepository) async throws -> String {
    try await runRaw(Self.finishGitFlowArguments(kind: kind, name: name), in: repository)
  }

  static func finishGitFlowArguments(kind: GitFlowStartKind, name: String) -> [String] {
    ["flow", kind.rawValue, "finish", name]
  }

  func resolveConflict(_ entry: GitStatusEntry, choice: ConflictResolutionChoice, in repository: GitRepository) async throws -> String {
    var outputs: [String] = []
    for arguments in Self.resolveConflictArguments(entry, choice: choice) {
      outputs.append(try await runRaw(arguments, in: repository))
    }
    return outputs.filter { !$0.isEmpty }.joined(separator: "\n")
  }

  static func resolveConflictArguments(_ entry: GitStatusEntry, choice: ConflictResolutionChoice) -> [[String]] {
    switch choice {
    case .ours:
      return [conflictCheckoutArguments(entry, side: "--ours"), markConflictResolvedArguments(entry)]
    case .theirs:
      return [conflictCheckoutArguments(entry, side: "--theirs"), markConflictResolvedArguments(entry)]
    case .markResolved:
      return [markConflictResolvedArguments(entry)]
    }
  }

  static func conflictCheckoutArguments(_ entry: GitStatusEntry, side: String) -> [String] {
    ["checkout", side, "--", entry.path]
  }

  static func markConflictResolvedArguments(_ entry: GitStatusEntry) -> [String] {
    ["add", "--", entry.path]
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
    let output = try await git(Self.interactiveRebasePlanArguments(count: count), in: repository.url)

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

    let upstream = try? await git(Self.rebaseUpstreamVerificationArguments(firstHash: first.hash), in: repository.url)
    return InteractiveRebasePlan(upstream: upstream == nil ? "--root" : "\(first.hash)^", items: items)
  }

  static func interactiveRebasePlanArguments(count: Int) -> [String] {
    let format = "%H%x1f%h%x1f%s"
    return [
      "log",
      "--reverse",
      "--pretty=format:\(format)",
      "-n",
      "\(count)"
    ]
  }

  static func rebaseUpstreamVerificationArguments(firstHash: String) -> [String] {
    ["rev-parse", "--verify", "\(firstHash)^"]
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
      Self.startInteractiveRebaseArguments(plan),
      in: repository.url,
      environment: [
        "GIT_SEQUENCE_EDITOR": editorURL.path(percentEncoded: false),
        "BONSAI_REBASE_TODO": todoURL.path(percentEncoded: false)
      ]
    )
    return output.combinedOutput
  }

  static func startInteractiveRebaseArguments(_ plan: InteractiveRebasePlan) -> [String] {
    var arguments = ["rebase", "-i"]
    if plan.updateRefs {
      arguments.append("--update-refs")
    }
    arguments.append(plan.upstream)
    return arguments
  }

  func reflog(in repository: GitRepository) async throws -> String {
    try await runRaw(Self.reflogArguments(), in: repository)
  }

  static func reflogArguments() -> [String] {
    ["reflog", "--date=iso"]
  }

  func reflogEntries(in repository: GitRepository) async throws -> [GitReflogEntry] {
    let output = try await git(Self.reflogEntriesArguments(), in: repository.url)
    return GitParsers.parseReflogEntries(output.stdout)
  }

  static func reflogEntriesArguments() -> [String] {
    [
      "log",
      "-g",
      "--pretty=format:%H%x1f%h%x1f%gd%x1f%gs%x1f%aI",
      "-n",
      "100"
    ]
  }

  func blame(path: String, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.blameArguments(path: path), in: repository.url)
    return output.stdout
  }

  func blameLines(path: String, in repository: GitRepository) async throws -> [GitBlameLine] {
    let output = try await git(Self.blameArguments(path: path), in: repository.url)
    return GitParsers.parseBlameLines(output.stdout)
  }

  static func blameArguments(path: String) -> [String] {
    ["blame", "--line-porcelain", "--", path]
  }

  func fileHistory(path: String, in repository: GitRepository) async throws -> String {
    let output = try await git(Self.fileHistoryArguments(path: path), in: repository.url)
    return output.stdout
  }

  static func fileHistoryArguments(path: String) -> [String] {
    [
      "log",
      "--follow",
      "--date=iso",
      "--stat",
      "--",
      path
    ]
  }

  func fileHistoryEntries(path: String, in repository: GitRepository) async throws -> [GitFileHistoryEntry] {
    let output = try await git(Self.fileHistoryEntriesArguments(path: path), in: repository.url)
    return GitParsers.parseFileHistoryEntries(output.stdout)
  }

  static func fileHistoryEntriesArguments(path: String) -> [String] {
    let format = "%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s"
    return [
      "log",
      "--follow",
      "--date=iso-strict",
      "--pretty=format:\(format)",
      "--name-status",
      "--",
      path
    ]
  }

  func lineHistoryEntries(path: String, startLine: Int, endLine: Int, in repository: GitRepository) async throws -> [GitFileHistoryEntry] {
    let output = try await git(Self.lineHistoryEntriesArguments(path: path, startLine: startLine, endLine: endLine), in: repository.url)
    return GitParsers.parseLineHistoryEntries(output.stdout)
  }

  static func lineHistoryEntriesArguments(path: String, startLine: Int, endLine: Int) -> [String] {
    let format = "%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s"
    let range = "\(max(startLine, 1)),\(max(endLine, startLine)):\(path)"
    return [
      "log",
      "-L",
      range,
      "--date=iso-strict",
      "--pretty=format:\(format)"
    ]
  }

  func git(_ arguments: [String], in directory: URL?, standardInput: String? = nil, environment: [String: String]? = nil) async throws -> ProcessOutput {
    try await runner.run(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory, standardInput: standardInput, environment: environment)
  }

  func gitData(_ arguments: [String], in directory: URL?) async throws -> ProcessDataOutput {
    try await runner.runData(gitExecutable, arguments: ["git"] + arguments, currentDirectory: directory)
  }

  private func measuredGit(
    _ arguments: [String],
    title: String,
    detail: String,
    in repository: GitRepository
  ) async throws -> (stdout: String, timing: RepositoryBenchmarkTiming) {
    let startedAt = Date()
    let output = try await git(arguments, in: repository.url)
    let milliseconds = max(Int((Date().timeIntervalSince(startedAt) * 1000).rounded()), 0)
    return (
      output.stdout,
      RepositoryBenchmarkTiming(title: title, milliseconds: milliseconds, detail: detail)
    )
  }

  private static func diffArguments(_ suffix: [String], algorithm: DiffAlgorithm, whitespaceMode: DiffWhitespaceMode) -> [String] {
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
      let output = try await gitData(Self.conflictStageTextArguments(stage: stage, path: path), in: repository.url)
      guard let text = String(data: output.stdout, encoding: .utf8) else {
        return "\(side.title) is not UTF-8 text."
      }
      return limitedConflictPreview(text)
    } catch {
      return side.unavailableText
    }
  }

  static func conflictStageTextArguments(stage: Int, path: String) -> [String] {
    ["show", ":\(stage):\(path)"]
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
    guard let output = try? await git(Self.configValueArguments(key), in: repository.url) else { return nil }
    let value = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }

  static func configValueArguments(_ key: String) -> [String] {
    ["config", "--get", key]
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
    guard let output = try? await git(Self.gitPathArguments(path), in: repository.url) else { return false }
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

  static func gitPathArguments(_ path: String) -> [String] {
    ["rev-parse", "--git-path", path]
  }

  private func bisectStatus(in repository: GitRepository) async -> GitBisectStatus {
    guard let refs = try? await git(Self.bisectRefsArguments(), in: repository.url) else {
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

    if let head = try? await git(Self.headRevisionArguments(short: false), in: repository.url),
       let shortHead = try? await git(Self.headRevisionArguments(short: true), in: repository.url) {
      status.currentHash = head.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
      status.currentShortHash = shortHead.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    status.goodRevisions.sort()
    status.skippedRevisions.sort()
    return status
  }

  static func bisectRefsArguments() -> [String] {
    [
      "for-each-ref",
      "refs/bisect",
      "--format=%(refname)%1f%(objectname)%1f%(objectname:short)"
    ]
  }

  static func headRevisionArguments(short: Bool) -> [String] {
    short ? ["rev-parse", "--short", "HEAD"] : ["rev-parse", "HEAD"]
  }

  private func lfsFiles(in repository: GitRepository) async -> [GitLFSFile] {
    guard let output = try? await git(Self.lfsFilesArguments(), in: repository.url) else { return [] }
    return GitParsers.parseLFSFiles(output.stdout)
  }

  static func lfsFilesArguments() -> [String] {
    ["lfs", "ls-files"]
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
