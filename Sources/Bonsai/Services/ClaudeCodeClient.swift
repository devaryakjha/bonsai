import Foundation

enum ClaudeCodeClientError: LocalizedError {
  case notInstalled
  case noStagedChanges
  case emptyResponse

  var errorDescription: String? {
    switch self {
    case .notInstalled:
      return "Claude Code is not installed or is not on PATH."
    case .noStagedChanges:
      return "Stage changes before generating a commit message."
    case .emptyResponse:
      return "Claude did not return a commit message."
    }
  }
}

struct ClaudeCodeClient {
  static let maxDiffCharacters = 60_000

  private let runner = ProcessRunner()
  private let gitClient = GitClient()
  private let executableResolver: () -> String?

  init(executableResolver: @escaping () -> String? = Self.resolveExecutable) {
    self.executableResolver = executableResolver
  }

  func generateCommitMessage(in repository: GitRepository) async throws -> String {
    guard let executable = executableResolver() else {
      throw ClaudeCodeClientError.notInstalled
    }

    let repositoryURL = URL(filePath: repository.path, directoryHint: .isDirectory)
    let diffStat = try await gitClient.git(Self.stagedDiffStatArguments(), in: repositoryURL).stdout
    let stagedDiff = try await gitClient.git(Self.stagedDiffArguments(), in: repositoryURL).stdout

    guard !stagedDiff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ClaudeCodeClientError.noStagedChanges
    }

    let prompt = Self.commitMessagePrompt(diffStat: diffStat, stagedDiff: stagedDiff)
    let output = try await runner.run(
      executable,
      arguments: Self.claudePrintArguments(),
      currentDirectory: repositoryURL,
      standardInput: prompt
    )
    let message = Self.normalizedCommitMessage(from: output.stdout)

    guard !message.isEmpty else {
      throw ClaudeCodeClientError.emptyResponse
    }

    return message
  }

  static func stagedDiffStatArguments() -> [String] {
    ["diff", "--cached", "--stat"]
  }

  static func stagedDiffArguments() -> [String] {
    ["diff", "--cached", "--find-renames", "--find-copies", "--"]
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

  static func commitMessagePrompt(diffStat: String, stagedDiff: String) -> String {
    let boundedDiff = bounded(stagedDiff, limit: maxDiffCharacters)
    return """
    Write a Git commit message for the staged changes below.

    Requirements:
    - Return only the commit message text.
    - Use a concise imperative subject, 72 characters or less when practical.
    - Add a short body only when it materially helps future readers.
    - Do not use Markdown fences, bullet labels, signatures, trailers, or AI attribution.
    - Do not mention Claude.

    Diffstat:
    \(diffStat.trimmingCharacters(in: .whitespacesAndNewlines))

    Staged diff:
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

  static func resolveExecutable() -> String? {
    let environment = ProcessInfo.processInfo.environment
    let pathEntries = (environment["PATH"] ?? "")
      .split(separator: ":")
      .map(String.init)

    let home = NSHomeDirectory()
    let candidates = pathEntries.map { "\($0)/claude" } + [
      "\(home)/.local/bin/claude",
      "/opt/homebrew/bin/claude",
      "/usr/local/bin/claude"
    ]

    return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
  }
}
