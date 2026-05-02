import Foundation

enum CodeAgentProvider: String, CaseIterable, Hashable {
  case claude
  case codex

  var displayName: String {
    switch self {
    case .claude:
      return "Claude Code"
    case .codex:
      return "Codex CLI"
    }
  }

  var executableName: String {
    switch self {
    case .claude:
      return "claude"
    case .codex:
      return "codex"
    }
  }
}

enum CodeAgentClientError: LocalizedError {
  case notInstalled(CodeAgentProvider)
  case noStagedChanges
  case noCurrentBranch
  case noBranchChanges
  case baseRevisionNotFound
  case emptyResponse(CodeAgentProvider)

  var errorDescription: String? {
    switch self {
    case .notInstalled(let provider):
      return "\(provider.displayName) is not installed or is not on PATH."
    case .noStagedChanges:
      return "Stage changes before generating a commit message."
    case .noCurrentBranch:
      return "Checkout a branch before running branch review."
    case .noBranchChanges:
      return "The current branch has no changes to review."
    case .baseRevisionNotFound:
      return "Could not find a base revision for branch review."
    case .emptyResponse(let provider):
      return "\(provider.displayName) did not return output."
    }
  }
}

struct CodeAgentClient {
  static let maxDiffCharacters = 60_000

  private let runner = ProcessRunner()
  private let gitClient = GitClient()
  private let executableResolver: (CodeAgentProvider) -> String?

  init(executableResolver: @escaping (CodeAgentProvider) -> String? = Self.resolveExecutable) {
    self.executableResolver = executableResolver
  }

  func generateCommitMessage(with provider: CodeAgentProvider, in repository: GitRepository) async throws -> String {
    guard let executable = executableResolver(provider) else {
      throw CodeAgentClientError.notInstalled(provider)
    }

    let repositoryURL = URL(filePath: repository.path, directoryHint: .isDirectory)
    let diffStat = try await gitClient.git(Self.stagedDiffStatArguments(), in: repositoryURL).stdout
    let stagedDiff = try await gitClient.git(Self.stagedDiffArguments(), in: repositoryURL).stdout

    guard !stagedDiff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw CodeAgentClientError.noStagedChanges
    }

    let prompt = Self.commitMessagePrompt(diffStat: diffStat, stagedDiff: stagedDiff)
    let output = try await runner.run(
      executable,
      arguments: Self.agentArguments(for: provider),
      currentDirectory: repositoryURL,
      standardInput: prompt
    )
    let message = Self.normalizedCommitMessage(from: output.stdout)

    guard !message.isEmpty else {
      throw CodeAgentClientError.emptyResponse(provider)
    }

    return message
  }

  func reviewCurrentBranch(
    _ branch: GitRef?,
    with provider: CodeAgentProvider,
    in repository: GitRepository
  ) async throws -> CodeAgentBranchReviewDocument {
    guard let executable = executableResolver(provider) else {
      throw CodeAgentClientError.notInstalled(provider)
    }
    guard let branch else {
      throw CodeAgentClientError.noCurrentBranch
    }

    let repositoryURL = URL(filePath: repository.path, directoryHint: .isDirectory)
    let baseReference = try await branchReviewBaseReference(for: branch, in: repositoryURL)
    let diffRange = "\(baseReference)...HEAD"
    let diffStat = try await gitClient.git(Self.branchReviewDiffStatArguments(diffRange: diffRange), in: repositoryURL).stdout
    let branchDiff = try await gitClient.git(Self.branchReviewDiffArguments(diffRange: diffRange), in: repositoryURL).stdout

    guard !branchDiff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw CodeAgentClientError.noBranchChanges
    }

    let prompt = Self.branchReviewPrompt(
      branchName: branch.shortName,
      baseReference: baseReference,
      diffStat: diffStat,
      branchDiff: branchDiff
    )
    let output = try await runner.run(
      executable,
      arguments: Self.agentArguments(for: provider),
      currentDirectory: repositoryURL,
      standardInput: prompt
    )
    let review = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !review.isEmpty else {
      throw CodeAgentClientError.emptyResponse(provider)
    }

    return CodeAgentBranchReviewDocument(
      repository: repository,
      providerName: provider.displayName,
      branchName: branch.shortName,
      baseReference: baseReference,
      generatedAt: Date(),
      text: review
    )
  }

  static func stagedDiffStatArguments() -> [String] {
    ["diff", "--cached", "--stat"]
  }

  static func stagedDiffArguments() -> [String] {
    ["diff", "--cached", "--find-renames", "--find-copies", "--"]
  }

  static func branchReviewBaseCandidates(for branch: GitRef) -> [String] {
    var candidates: [String] = []
    if let upstream = branch.upstream, !upstream.isEmpty {
      candidates.append(upstream)
    }
    candidates.append(contentsOf: ["origin/main", "origin/master", "main", "master"])
    return candidates.reduce(into: []) { result, candidate in
      if !result.contains(candidate) {
        result.append(candidate)
      }
    }
  }

  static func branchReviewBaseArguments(candidate: String) -> [String] {
    ["merge-base", "HEAD", candidate]
  }

  static func branchReviewDiffStatArguments(diffRange: String) -> [String] {
    ["diff", "--stat", diffRange]
  }

  static func branchReviewDiffArguments(diffRange: String) -> [String] {
    ["diff", "--find-renames", "--find-copies", diffRange, "--"]
  }

  static func agentArguments(for provider: CodeAgentProvider) -> [String] {
    switch provider {
    case .claude:
      return claudePrintArguments()
    case .codex:
      return codexExecArguments()
    }
  }

  static func claudePrintArguments() -> [String] {
    [
      "--print",
      "--no-session-persistence",
      "--permission-mode",
      "dontAsk",
      "--max-budget-usd",
      "0.25"
    ]
  }

  static func codexExecArguments() -> [String] {
    [
      "exec",
      "--sandbox",
      "read-only",
      "--ask-for-approval",
      "never",
      "--ephemeral",
      "--color",
      "never",
      "-"
    ]
  }

  static func commitMessagePrompt(diffStat: String, stagedDiff: String) -> String {
    let boundedDiff = bounded(stagedDiff, limit: maxDiffCharacters)
    return """
    Write a Git commit message for the staged changes below.

    Requirements:
    - Return only the commit message text.
    - Use a concise imperative subject, 72 characters or less when practical.
    - Add a short body only when it materially helps future readers.
    - Do not use Markdown fences, bullet labels, signatures, trailers, or AI attribution.
    - Do not mention AI tooling.

    Diffstat:
    \(diffStat.trimmingCharacters(in: .whitespacesAndNewlines))

    Staged diff:
    \(boundedDiff)
    """
  }

  static func branchReviewPrompt(branchName: String, baseReference: String, diffStat: String, branchDiff: String) -> String {
    let boundedDiff = bounded(branchDiff, limit: maxDiffCharacters)
    return """
    Review the current Git branch diff.

    Requirements:
    - Return only the review text.
    - Lead with findings ordered by severity.
    - Include concrete file/function references when the diff provides enough context.
    - Include test gaps or residual risk when relevant.
    - If there are no issues, say that clearly and keep the answer short.
    - Do not edit files, run commands, or include AI attribution.

    Branch: \(branchName)
    Base: \(baseReference)

    Diffstat:
    \(diffStat.trimmingCharacters(in: .whitespacesAndNewlines))

    Branch diff:
    \(boundedDiff)
    """
  }

  static func normalizedCommitMessage(from output: String) -> String {
    let droppedPrefixes = [
      "commit message:",
      "here is a commit message:",
      "here's a commit message:"
    ]

    var lines = output
      .replacingOccurrences(of: "\r\n", with: "\n")
      .components(separatedBy: "\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { line in
        !line.hasPrefix("```")
          && !line.localizedCaseInsensitiveContains("generated with claude")
          && !line.localizedCaseInsensitiveContains("generated with codex")
          && !line.localizedCaseInsensitiveContains("co-authored-by:")
      }

    while let first = lines.first, first.isEmpty {
      lines.removeFirst()
    }
    while let last = lines.last, last.isEmpty {
      lines.removeLast()
    }

    guard var first = lines.first else { return "" }
    let lowercasedFirst = first.lowercased()
    for prefix in droppedPrefixes where lowercasedFirst.hasPrefix(prefix) {
      first = String(first.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
      lines[0] = first
      break
    }

    return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static func bounded(_ value: String, limit: Int) -> String {
    guard value.count > limit else { return value }
    let prefix = value.prefix(limit)
    return "\(prefix)\n\n[Diff truncated to \(limit) characters]"
  }

  static func resolveExecutable(for provider: CodeAgentProvider) -> String? {
    let environment = ProcessInfo.processInfo.environment
    let pathEntries = (environment["PATH"] ?? "")
      .split(separator: ":")
      .map(String.init)

    let home = NSHomeDirectory()
    let executableName = provider.executableName
    let candidates = pathEntries.map { "\($0)/\(executableName)" } + [
      "\(home)/.local/bin/\(executableName)",
      "\(home)/.bun/bin/\(executableName)",
      "/opt/homebrew/bin/\(executableName)",
      "/usr/local/bin/\(executableName)"
    ]

    return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
  }

  private func branchReviewBaseReference(for branch: GitRef, in repositoryURL: URL) async throws -> String {
    for candidate in Self.branchReviewBaseCandidates(for: branch) {
      do {
        let output = try await gitClient.git(Self.branchReviewBaseArguments(candidate: candidate), in: repositoryURL)
        let hash = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !hash.isEmpty {
          return hash
        }
      } catch {
        continue
      }
    }
    throw CodeAgentClientError.baseRevisionNotFound
  }
}
