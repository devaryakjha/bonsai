import Foundation

struct GitRepository: Identifiable, Hashable, Codable {
  var path: String

  var id: String { path }
  var name: String { URL(filePath: path).lastPathComponent }
}

struct WorkspaceGroup: Identifiable, Hashable {
  var name: String
  var path: String
  var repositories: [GitRepository]

  var id: String { path }
}

struct GitStatusEntry: Identifiable, Hashable {
  enum ChangeKind: String {
    case modified = "Modified"
    case added = "Added"
    case deleted = "Deleted"
    case renamed = "Renamed"
    case copied = "Copied"
    case untracked = "Untracked"
    case conflicted = "Conflicted"
    case typeChanged = "Type changed"
    case unknown = "Changed"
  }

  var path: String
  var originalPath: String?
  var indexStatus: Character
  var workTreeStatus: Character
  var kind: ChangeKind

  var id: String { "\(indexStatus)\(workTreeStatus):\(path)" }
  var isStaged: Bool { indexStatus != " " && indexStatus != "?" && indexStatus != "!" }
  var isUntracked: Bool { indexStatus == "?" || workTreeStatus == "?" }
  var isConflicted: Bool {
    ["DD", "AU", "UD", "UA", "DU", "AA", "UU"].contains("\(indexStatus)\(workTreeStatus)")
  }
  var statusCode: String {
    switch kind {
    case .modified:
      return "M"
    case .added:
      return "A"
    case .deleted:
      return "D"
    case .renamed:
      return "R"
    case .copied:
      return "C"
    case .untracked:
      return "?"
    case .conflicted:
      return "U"
    case .typeChanged:
      return "T"
    case .unknown:
      return "?"
    }
  }
  var statusTitle: String { kind.rawValue }
}

struct GitCommit: Identifiable, Hashable {
  var hash: String
  var shortHash: String
  var authorName: String
  var authorEmail: String
  var date: Date?
  var subject: String
  var decorations: [String]
  var graph: String = ""

  var id: String { hash }
}

struct GitChangedFile: Identifiable, Hashable {
  var status: String
  var path: String
  var oldPath: String?

  var id: String { "\(status):\(oldPath ?? ""):\(path)" }
  var statusCode: String {
    guard let first = status.first else { return "?" }
    return String(first)
  }
  var statusTitle: String {
    switch statusCode {
    case "M":
      return "Modified"
    case "A":
      return "Added"
    case "D":
      return "Deleted"
    case "R":
      return status.count > 1 ? "Renamed (\(status))" : "Renamed"
    case "C":
      return status.count > 1 ? "Copied (\(status))" : "Copied"
    case "U":
      return "Conflicted"
    case "T":
      return "Type changed"
    case "?":
      return "Untracked"
    default:
      return "Changed (\(status))"
    }
  }
}

struct GitTreeEntry: Identifiable, Hashable {
  enum EntryKind: String {
    case tree
    case blob
    case commit
    case unknown

    var title: String {
      switch self {
      case .tree:
        return "Folder"
      case .blob:
        return "File"
      case .commit:
        return "Submodule"
      case .unknown:
        return "Unknown"
      }
    }
  }

  var mode: String
  var kind: EntryKind
  var object: String
  var path: String
  var name: String

  var id: String { "\(kind.rawValue):\(path)" }
  var isDirectory: Bool { kind == .tree }
  var kindTitle: String { kind.title }
}

struct GitRef: Identifiable, Hashable {
  enum RefKind: String {
    case localBranch = "Local"
    case remoteBranch = "Remote"
    case tag = "Tag"
  }

  var name: String
  var shortName: String
  var objectName: String
  var upstream: String?
  var ahead: Int = 0
  var behind: Int = 0
  var upstreamGone: Bool = false
  var isHead: Bool
  var kind: RefKind

  var id: String { "\(kind.rawValue):\(name)" }
  var trackingSummary: String? {
    if upstreamGone {
      return "gone"
    }
    if ahead == 0 && behind == 0 {
      return nil
    }
    var parts: [String] = []
    if ahead > 0 { parts.append("↑ \(ahead)") }
    if behind > 0 { parts.append("↓ \(behind)") }
    return parts.joined(separator: " ")
  }
  var pullTitle: String {
    behind > 0 ? "Pull ↓ \(behind)" : "Pull"
  }
  var pushTitle: String {
    ahead > 0 ? "Push ↑ \(ahead)" : "Push"
  }

  var upstreamRemoteName: String? {
    upstreamParts?.remote
  }

  var upstreamBranchName: String? {
    upstreamParts?.branch
  }

  var remoteTrackingLocalName: String? {
    remoteBranchName
  }

  var remoteName: String? {
    remoteBranchParts?.remote
  }

  var remoteBranchName: String? {
    remoteBranchParts?.branch
  }

  var isConcreteRemoteBranch: Bool {
    remoteBranchParts != nil
  }

  private var remoteBranchParts: (remote: String, branch: String)? {
    guard kind == .remoteBranch else { return nil }
    let parts = shortName.split(separator: "/", maxSplits: 1).map(String.init)
    guard parts.count == 2, parts[1] != "HEAD" else { return nil }
    return (parts[0], parts[1])
  }

  private var upstreamParts: (remote: String, branch: String)? {
    guard kind == .localBranch, let upstream else { return nil }
    let parts = upstream.split(separator: "/", maxSplits: 1).map(String.init)
    guard parts.count == 2 else { return nil }
    return (parts[0], parts[1])
  }
}

struct GitRemote: Identifiable, Hashable {
  var name: String
  var fetchURL: String?
  var pushURL: String?

  var id: String { name }

  var repositoryWebTarget: RepositoryWebTarget? {
    [fetchURL, pushURL]
      .compactMap { $0 }
      .compactMap(RepositoryWebTarget.init(remoteURL:))
      .first
  }

  var webURL: URL? {
    repositoryWebTarget?.webURL
  }

  func branchWebURL(branchName: String) -> URL? {
    repositoryWebTarget?.branchWebURL(branchName)
  }

  func tagWebURL(tagName: String) -> URL? {
    repositoryWebTarget?.tagWebURL(tagName)
  }

  var githubRepositoryTarget: GitHubRepositoryTarget? {
    [fetchURL, pushURL]
      .compactMap { $0 }
      .compactMap(GitHubRepositoryTarget.init(remoteURL:))
      .first
  }
  var githubWebURL: URL? {
    githubRepositoryTarget?.webURL
  }

  func githubBranchWebURL(branchName: String) -> URL? {
    githubRepositoryTarget?.branchWebURL(branchName)
  }

  func githubTagWebURL(tagName: String) -> URL? {
    githubRepositoryTarget?.tagWebURL(tagName)
  }
}

struct GitStash: Identifiable, Hashable {
  var index: String
  var branch: String?
  var message: String

  var id: String { index }
}

struct GitReflogEntry: Identifiable, Hashable {
  var hash: String
  var shortHash: String
  var selector: String
  var subject: String
  var date: Date?

  var id: String { "\(selector):\(hash)" }
}

struct GitBlameLine: Identifiable, Hashable {
  var id: Int
  var commitHash: String
  var shortHash: String
  var author: String
  var authorMail: String?
  var authorTime: Date?
  var originalLine: Int
  var finalLine: Int
  var content: String

  func lineReference(path: String) -> String {
    "\(path):\(finalLine)"
  }
}

struct GitBlameDocument: Identifiable, Hashable {
  var path: String
  var lines: [GitBlameLine]

  var id: String { path }
}

struct GitFileHistoryEntry: Identifiable, Hashable {
  var hash: String
  var shortHash: String
  var authorName: String
  var authorEmail: String
  var date: Date?
  var subject: String
  var changes: [GitChangedFile]

  var id: String { hash }
  var changedPathsForCopy: String {
    uniqueChangeValues(\.path).joined(separator: "\n")
  }
  var changedPathCopyCount: Int {
    uniqueChangeValues(\.path).count
  }
  var previousPathsForCopy: String? {
    let paths = uniqueChangeValues(\.oldPath)
    return paths.isEmpty ? nil : paths.joined(separator: "\n")
  }
  var previousPathCopyCount: Int {
    uniqueChangeValues(\.oldPath).count
  }

  private func uniqueChangeValues(_ keyPath: KeyPath<GitChangedFile, String?>) -> [String] {
    var seen: Set<String> = []
    var values: [String] = []

    for change in changes {
      guard let value = change[keyPath: keyPath], !value.isEmpty, seen.insert(value).inserted else {
        continue
      }
      values.append(value)
    }

    return values
  }

  private func uniqueChangeValues(_ keyPath: KeyPath<GitChangedFile, String>) -> [String] {
    var seen: Set<String> = []
    var values: [String] = []

    for change in changes {
      let value = change[keyPath: keyPath]
      guard !value.isEmpty, seen.insert(value).inserted else { continue }
      values.append(value)
    }

    return values
  }
}

struct GitFileHistoryDocument: Identifiable, Hashable {
  var path: String
  var entries: [GitFileHistoryEntry]

  var id: String { path }
}

struct GitLineHistoryDocument: Identifiable, Hashable {
  var path: String
  var startLine: Int
  var endLine: Int
  var entries: [GitFileHistoryEntry]

  var id: String { "\(path):\(startLine)-\(endLine)" }
  var rangeTitle: String {
    startLine == endLine ? "line \(startLine)" : "lines \(startLine)-\(endLine)"
  }
}

struct GitSubmodule: Identifiable, Hashable {
  var path: String
  var commit: String
  var status: String

  var id: String { path }
  var shortCommit: String { String(commit.prefix(7)) }
  func directoryURL(in repository: GitRepository) -> URL {
    URL(filePath: repository.path).appending(path: path)
  }

  var statusTitle: String {
    switch status {
    case "-":
      return "Not initialized"
    case "+":
      return "Changed"
    case "U":
      return "Conflicted"
    default:
      return "Ready"
    }
  }
  var statusColorToken: GitChangeStatusColorToken {
    switch status {
    case "+":
      return .amber
    case "U":
      return .orange
    default:
      return .neutral
    }
  }
}

struct GitWorktree: Identifiable, Hashable {
  var path: String
  var head: String?
  var branch: String?
  var isDetached: Bool
  var isBare: Bool
  var isPrunable: Bool

  var id: String { path }
  var name: String { URL(filePath: path).lastPathComponent }
  var directoryURL: URL { URL(filePath: path) }
  var displayState: String {
    if let branch {
      return branch.replacingOccurrences(of: "refs/heads/", with: "")
    }
    if isDetached {
      return "Detached"
    }
    if isBare {
      return "Bare"
    }
    return head.map { String($0.prefix(7)) } ?? "Unknown"
  }
}

struct GitLFSFile: Identifiable, Hashable {
  var oid: String
  var path: String

  var id: String { path }
  var shortOID: String { String(oid.prefix(10)) }
  var sidebarTitle: String { path }
  var sidebarDetail: String { shortOID }
  func fileURL(in repository: GitRepository) -> URL {
    RepositoryFileLocator.fileURL(repository: repository, path: path)
  }

  var sidebarHelpText: String {
    """
    Path: \(path)
    Object ID: \(oid)
    """
  }
}

struct GitBisectStatus: Hashable {
  var active = false
  var currentHash: String?
  var currentShortHash: String?
  var badRevision: String?
  var goodRevisions: [String] = []
  var skippedRevisions: [String] = []

  var detail: String {
    guard active else { return "Inactive" }
    var parts: [String] = []
    if let currentShortHash {
      parts.append("testing \(currentShortHash)")
    }
    if let badRevision {
      parts.append("bad \(String(badRevision.prefix(7)))")
    }
    if !goodRevisions.isEmpty {
      parts.append("\(goodRevisions.count) good")
    }
    if !skippedRevisions.isEmpty {
      parts.append("\(skippedRevisions.count) skipped")
    }
    return parts.isEmpty ? "Active" : parts.joined(separator: " / ")
  }
}

enum GitBisectMark: String, CaseIterable, Identifiable {
  case good
  case bad
  case skip

  var id: String { rawValue }
  var title: String { rawValue.capitalized }
}

enum GitInProgressOperationKind: String, Identifiable {
  case merge
  case rebase
  case cherryPick
  case revert

  var id: String { rawValue }
  var title: String {
    switch self {
    case .merge:
      return "Merge"
    case .rebase:
      return "Rebase"
    case .cherryPick:
      return "Cherry-pick"
    case .revert:
      return "Revert"
    }
  }
  var command: String {
    switch self {
    case .cherryPick:
      return "cherry-pick"
    default:
      return rawValue
    }
  }
  var canSkip: Bool {
    self != .merge
  }
}

enum GitInProgressOperationAction: String, Identifiable {
  case continueOperation = "continue"
  case abort
  case skip

  var id: String { rawValue }
  var title: String {
    switch self {
    case .continueOperation:
      return "Continue"
    case .abort:
      return "Abort"
    case .skip:
      return "Skip"
    }
  }
  var flag: String { "--\(rawValue)" }
}

struct GitInProgressOperationStatus: Hashable {
  var kind: GitInProgressOperationKind?

  var active: Bool { kind != nil }
  var title: String { kind.map { "\($0.title) in progress" } ?? "No operation" }
}

struct GitIntegrationStatus: Hashable {
  var lfsAvailable = false
  var lfsFiles: [GitLFSFile] = []
  var gpgSigningEnabled = false
  var signingKey: String?
  var gitFlowAvailable = false
  var gitFlowInitialized = false
  var gitFlowMainBranch: String?
  var gitFlowDevelopBranch: String?
  var bisect = GitBisectStatus()
}

struct GitHubNotification: Identifiable, Hashable, Decodable {
  struct Subject: Hashable, Decodable {
    var title: String
    var type: String
    var url: String?
  }

  struct Repository: Hashable, Decodable {
    var fullName: String

    enum CodingKeys: String, CodingKey {
      case fullName = "full_name"
    }
  }

  var id: String
  var unread: Bool
  var reason: String
  var updatedAt: String
  var subject: Subject
  var repository: Repository

  enum CodingKeys: String, CodingKey {
    case id
    case unread
    case reason
    case updatedAt = "updated_at"
    case subject
    case repository
  }

  var webURL: URL? {
    if let subjectURL = subject.url, let url = GitHubNotification.webURL(fromAPIURL: subjectURL) {
      return url
    }
    return URL(string: "https://github.com/\(repository.fullName)")
  }

  var sidebarDetail: String {
    "\(repository.fullName) - \(subject.type)"
  }

  private static func webURL(fromAPIURL value: String) -> URL? {
    guard let url = URL(string: value), url.host == "api.github.com" else {
      return URL(string: value)
    }

    let parts = url.pathComponents.filter { $0 != "/" }
    guard let reposIndex = parts.firstIndex(of: "repos"),
          parts.count > reposIndex + 2 else {
      return nil
    }

    let owner = parts[reposIndex + 1]
    let repository = parts[reposIndex + 2]
    let remaining = Array(parts.dropFirst(reposIndex + 3)).map { part in
      part == "pulls" ? "pull" : part
    }
    let path = ([owner, repository] + remaining).joined(separator: "/")
    return URL(string: "https://github.com/\(path)")
  }
}

struct GitHubRepository: Identifiable, Hashable, Decodable {
  var id: Int
  var name: String
  var fullName: String
  var htmlURL: String
  var cloneURL: String?
  var sshURL: String?
  var isPrivate: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case fullName = "full_name"
    case htmlURL = "html_url"
    case cloneURL = "clone_url"
    case sshURL = "ssh_url"
    case isPrivate = "private"
  }
}

enum RepositoryWebProvider: String, Hashable {
  case github
  case gitlab
}

struct RepositoryWebTarget: Hashable {
  var provider: RepositoryWebProvider
  var host: String
  var projectPath: String

  var webURL: URL? {
    URL(string: "https://\(host)/\(encodedProjectPath)")
  }

  func branchWebURL(_ branchName: String) -> URL? {
    switch provider {
    case .github:
      treeWebURL(refName: branchName)
    case .gitlab:
      gitLabTreeWebURL(refName: branchName)
    }
  }

  func tagWebURL(_ tagName: String) -> URL? {
    branchWebURL(tagName)
  }

  func commitWebURL(_ hash: String) -> URL? {
    guard let encodedHash = hash.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return nil
    }
    switch provider {
    case .github:
      return URL(string: "https://\(host)/\(encodedProjectPath)/commit/\(encodedHash)")
    case .gitlab:
      return URL(string: "https://\(host)/\(encodedProjectPath)/-/commit/\(encodedHash)")
    }
  }

  init(provider: RepositoryWebProvider, host: String, projectPath: String) {
    self.provider = provider
    self.host = host
    self.projectPath = projectPath
  }

  init?(remoteURL: String) {
    guard let remote = ParsedRepositoryRemoteURL(remoteURL) else { return nil }
    if remote.host == "github.com" {
      provider = .github
    } else if remote.host.contains("gitlab") {
      provider = .gitlab
    } else {
      return nil
    }

    host = remote.host
    projectPath = remote.projectPath
  }

  private var encodedProjectPath: String {
    projectPath
      .split(separator: "/", omittingEmptySubsequences: true)
      .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
      .joined(separator: "/")
  }

  private func treeWebURL(refName: String) -> URL? {
    guard let encodedRef = refName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return nil
    }
    return URL(string: "https://\(host)/\(encodedProjectPath)/tree/\(encodedRef)")
  }

  private func gitLabTreeWebURL(refName: String) -> URL? {
    guard let encodedRef = refName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return nil
    }
    return URL(string: "https://\(host)/\(encodedProjectPath)/-/tree/\(encodedRef)")
  }
}

struct GitHubRepositoryTarget: Hashable {
  var owner: String
  var name: String

  var fullName: String { "\(owner)/\(name)" }
  var webURL: URL? { URL(string: "https://github.com/\(fullName)") }

  func branchWebURL(_ branchName: String) -> URL? {
    treeWebURL(refName: branchName)
  }

  func tagWebURL(_ tagName: String) -> URL? {
    treeWebURL(refName: tagName)
  }

  func commitWebURL(_ hash: String) -> URL? {
    guard let encodedHash = hash.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return nil
    }
    return URL(string: "https://github.com/\(fullName)/commit/\(encodedHash)")
  }

  private func treeWebURL(refName: String) -> URL? {
    guard let encodedRef = refName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return nil
    }
    return URL(string: "https://github.com/\(fullName)/tree/\(encodedRef)")
  }

  init(owner: String, name: String) {
    self.owner = owner
    self.name = name
  }

  init?(remoteURL: String) {
    guard let remote = ParsedRepositoryRemoteURL(remoteURL),
          remote.host == "github.com" else { return nil }

    let parts = remote.projectPath.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    guard parts.count == 2 else { return nil }

    owner = parts[0]
    name = parts[1]
  }
}

private struct ParsedRepositoryRemoteURL {
  var host: String
  var projectPath: String

  init?(_ remoteURL: String) {
    let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if let parsed = ParsedRepositoryRemoteURL.parseStandardURL(trimmed) {
      self = parsed
      return
    }
    if let parsed = ParsedRepositoryRemoteURL.parseSCPStyleURL(trimmed) {
      self = parsed
      return
    }
    return nil
  }

  private static func parseStandardURL(_ value: String) -> ParsedRepositoryRemoteURL? {
    guard let url = URL(string: value),
          let host = url.host?.lowercased() else { return nil }
    return ParsedRepositoryRemoteURL(host: host, path: url.path)
  }

  private static func parseSCPStyleURL(_ value: String) -> ParsedRepositoryRemoteURL? {
    let parts = value.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2,
          let host = parts[0].split(separator: "@", maxSplits: 1).last.map(String.init)?.lowercased() else {
      return nil
    }
    return ParsedRepositoryRemoteURL(host: host, path: String(parts[1]))
  }

  private init?(host: String, path: String) {
    let cleanedPath = path
      .split(separator: "/", omittingEmptySubsequences: true)
      .map(String.init)
      .joined(separator: "/")
    let projectPath = cleanedPath.hasSuffix(".git") ? String(cleanedPath.dropLast(4)) : cleanedPath
    guard !host.isEmpty, !projectPath.isEmpty, projectPath.contains("/") else { return nil }

    self.host = host
    self.projectPath = projectPath
  }
}

enum GitHubRepositoryOperation: String, Identifiable {
  case create
  case delete

  var id: String { rawValue }
  var title: String { self == .create ? "Create GitHub repository" : "Delete GitHub repository" }
  var primaryActionTitle: String { self == .create ? "Create" : "Delete" }
}

struct GitHubRepositoryRequest: Identifiable, Hashable {
  var operation: GitHubRepositoryOperation
  var owner: String
  var name: String
  var repositoryDescription: String
  var isPrivate: Bool

  var id: String { operation.rawValue }

  var normalizedOwner: String {
    owner.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var normalizedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var normalizedDescription: String? {
    let value = repositoryDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }

  var validationMessage: String? {
    switch operation {
    case .create:
      return normalizedName.isEmpty ? "Repository name is required." : nil
    case .delete:
      if normalizedOwner.isEmpty {
        return "Repository owner is required."
      }
      return normalizedName.isEmpty ? "Repository name is required." : nil
    }
  }
}

struct RepositorySnapshot {
  var status: [GitStatusEntry] = []
  var commits: [GitCommit] = []
  var changedFiles: [GitChangedFile] = []
  var refs: [GitRef] = []
  var remotes: [GitRemote] = []
  var stashes: [GitStash] = []
  var submodules: [GitSubmodule] = []
  var worktrees: [GitWorktree] = []
  var integrations = GitIntegrationStatus()
  var inProgressOperation = GitInProgressOperationStatus()
}

struct CommandResult: Identifiable, Hashable {
  var id = UUID()
  var title: String
  var output: String
  var isError: Bool

  var summary: String {
    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return isError ? "Failed" : Self.completedOutput }
    return trimmed.components(separatedBy: .newlines).first ?? trimmed
  }

  static let completedOutput = "Completed"
  static let noOutput = "No output"
}

struct DiffHunk: Identifiable, Hashable {
  var id: Int
  var fileHeader: [String]
  var header: String
  var lines: [String]

  var patch: String {
    (fileHeader + [header] + lines).joined(separator: "\n") + "\n"
  }
}

struct DiffLineChange: Identifiable, Hashable {
  enum Kind: String {
    case addition = "Addition"
    case deletion = "Deletion"
    case replacement = "Replacement"
  }

  var id: String
  var hunkID: Int
  var kind: Kind
  var oldStart: Int
  var oldCount: Int
  var newStart: Int
  var newCount: Int
  var lines: [String]
  var fileHeader: [String]

  var patch: String {
    let header = "@@ -\(oldStart),\(oldCount) +\(newStart),\(newCount) @@"
    return (fileHeader + [header] + lines).joined(separator: "\n") + "\n"
  }

  var title: String {
    switch kind {
    case .addition:
      return "Add line \(newStart)"
    case .deletion:
      return "Remove line \(oldStart)"
    case .replacement:
      return "Replace line \(oldStart)"
    }
  }

  var discardDescription: String {
    switch kind {
    case .addition:
      return "added line \(newStart)"
    case .deletion:
      return "removed line \(oldStart)"
    case .replacement:
      return "replacement at line \(oldStart)"
    }
  }

  var historyStartLine: Int {
    if newCount > 0 {
      return max(newStart, 1)
    }
    return max(newStart, 1)
  }

  var historyEndLine: Int {
    let count = max(newCount, 1)
    return historyStartLine + count - 1
  }

  var historyTitle: String {
    historyStartLine == historyEndLine ? "Line \(historyStartLine)" : "Lines \(historyStartLine)-\(historyEndLine)"
  }
}

enum ConflictResolutionChoice: String {
  case ours = "Accept ours"
  case theirs = "Accept theirs"
  case markResolved = "Mark resolved"
}

enum ConflictPreviewSide: String, CaseIterable, Identifiable {
  case workingTree
  case base
  case ours
  case theirs

  var id: String { rawValue }

  var title: String {
    switch self {
    case .workingTree:
      "Working tree"
    case .base:
      "Base"
    case .ours:
      "Ours"
    case .theirs:
      "Theirs"
    }
  }

  var gitStage: Int? {
    switch self {
    case .workingTree:
      nil
    case .base:
      1
    case .ours:
      2
    case .theirs:
      3
    }
  }

  var unavailableText: String {
    switch self {
    case .workingTree:
      "Working-tree preview is unavailable."
    case .base:
      "No base version is available for this conflict."
    case .ours:
      "No ours version is available for this conflict."
    case .theirs:
      "No theirs version is available for this conflict."
    }
  }
}

struct ConflictPreview: Identifiable, Hashable {
  var side: ConflictPreviewSide
  var text: String

  var id: String { side.rawValue }
  var title: String { side.title }
}

struct ConflictResolutionRequest: Identifiable, Hashable {
  var entry: GitStatusEntry
  var previews: [ConflictPreview]

  var id: String { entry.id }

  var preview: String {
    previews.first(where: { $0.side == .workingTree })?.text ?? previews.first?.text ?? ""
  }
}

enum DiffAlgorithm: String, CaseIterable, Identifiable {
  case histogram
  case patience
  case myers
  case minimal

  var id: String { rawValue }
  var title: String { rawValue.capitalized }
}

enum DiffWhitespaceMode: String, CaseIterable, Identifiable {
  case show
  case ignoreChanges
  case ignoreAll

  var id: String { rawValue }

  var title: String {
    switch self {
    case .show:
      "Show whitespace"
    case .ignoreChanges:
      "Ignore whitespace changes"
    case .ignoreAll:
      "Ignore all whitespace"
    }
  }

  var gitArguments: [String] {
    switch self {
    case .show:
      []
    case .ignoreChanges:
      ["--ignore-space-change"]
    case .ignoreAll:
      ["--ignore-all-space"]
    }
  }
}

enum DiffDisplayMode: String, CaseIterable, Identifiable {
  case unified
  case split

  var id: String { rawValue }
  var title: String { self == .unified ? "Unified" : "Split" }
}

struct SplitDiffLine: Hashable {
  var number: Int?
  var text: String

  var changeMarker: String {
    if text.hasPrefix("+") {
      return "+"
    }
    if text.hasPrefix("-") {
      return "-"
    }
    return " "
  }

  var displayText: String {
    if text.hasPrefix("+") || text.hasPrefix("-") {
      return String(text.dropFirst())
    }
    return text
  }
}

struct SplitDiff: Hashable {
  var oldLines: [SplitDiffLine]
  var newLines: [SplitDiffLine]

  var gutterNumberWidth: Int {
    max(
      3,
      (oldLines + newLines)
        .compactMap(\.number)
        .map { "\($0)".count }
        .max() ?? 3
    )
  }

  var oldText: String {
    oldLines.map(\.text).joined(separator: "\n")
  }

  var newText: String {
    newLines.map(\.text).joined(separator: "\n")
  }
}

struct ImageDiffSnapshot: Hashable {
  var path: String
  var oldData: Data?
  var newData: Data?
}

enum RebaseTodoAction: String, CaseIterable, Identifiable {
  case pick
  case reword
  case edit
  case squash
  case fixup
  case drop

  var id: String { rawValue }
  var title: String { rawValue.capitalized }
}

struct InteractiveRebaseItem: Identifiable, Hashable {
  var id = UUID()
  var action: RebaseTodoAction
  var hash: String
  var shortHash: String
  var subject: String

  var todoLine: String {
    "\(action.rawValue) \(hash) \(subject)"
  }
}

struct InteractiveRebasePlan: Identifiable, Hashable {
  var id = UUID()
  var upstream: String
  var items: [InteractiveRebaseItem]
  var updateRefs = false

  var todoText: String {
    items.map(\.todoLine).joined(separator: "\n") + "\n"
  }
  var validationMessage: String? {
    guard let first = items.first else {
      return "No commits selected for rebase."
    }
    if first.action.requiresPreviousCommit {
      return "\(first.action.title) requires a previous commit."
    }
    return nil
  }
  var canStart: Bool {
    validationMessage == nil
  }
}

extension RebaseTodoAction {
  var requiresPreviousCommit: Bool {
    self == .squash || self == .fixup
  }
}

enum ResetMode: String, CaseIterable, Identifiable {
  case soft
  case mixed
  case hard

  var id: String { rawValue }
  var title: String { rawValue.capitalized }
  var flag: String { "--\(rawValue)" }
}

enum GitRevisionCommand: String, CaseIterable, Identifiable {
  case cherryPick = "cherry-pick"
  case revert
  case merge
  case rebase

  var id: String { rawValue }
  var gitSubcommand: String { rawValue }

  func arguments(commitHash: String, updateRefs: Bool = false) -> [String] {
    switch self {
    case .cherryPick, .revert, .merge:
      return [gitSubcommand, "--no-edit", commitHash]
    case .rebase:
      var arguments = [gitSubcommand]
      if updateRefs {
        arguments.append("--update-refs")
      }
      arguments.append(commitHash)
      return arguments
    }
  }

  var historyTitle: String {
    switch self {
    case .cherryPick:
      return "Cherry-pick"
    case .revert:
      return "Revert"
    case .merge:
      return "Merge"
    case .rebase:
      return "Rebase onto"
    }
  }

  var selectedCommitTitle: String {
    switch self {
    case .cherryPick:
      return "Cherry-pick selected commit"
    case .revert:
      return "Revert selected commit"
    case .merge:
      return "Merge selected commit"
    case .rebase:
      return "Rebase onto selected commit"
    }
  }

  func resultTitle(shortHash: String) -> String {
    "\(historyTitle) \(shortHash)"
  }
}

struct RevisionCommandRequest: Identifiable, Hashable {
  var command: GitRevisionCommand
  var commit: GitCommit

  var id: String { "\(command.rawValue):\(commit.hash)" }
  var title: String { command.selectedCommitTitle }
  var message: String { "\(command.historyTitle) \(commit.shortHash)." }
  var detail: String { commit.subject }
  var primaryActionTitle: String { command.historyTitle }
}

struct ResetRequest: Identifiable, Hashable {
  var commit: GitCommit
  var mode: ResetMode = .mixed

  var id: String { commit.hash }
}

struct AnnotatedTagRequest: Identifiable, Hashable {
  var id = UUID()
  var target: String?
  var targetDescription: String

  var title: String { "Create annotated tag" }
  var message: String { "Create an annotated tag at \(targetDescription)." }
}

struct ReflogResetRequest: Identifiable, Hashable {
  var entry: GitReflogEntry
  var mode: ResetMode = .mixed

  var id: String { entry.id }
}

struct DeleteRefRequest: Identifiable, Hashable {
  var ref: GitRef

  var id: String { ref.id }
  var allowsForceDelete: Bool { ref.kind == .localBranch }
  var title: String {
    switch ref.kind {
    case .localBranch:
      return "Delete branch"
    case .remoteBranch:
      return "Delete remote branch"
    case .tag:
      return "Delete tag"
    }
  }
  var message: String {
    switch ref.kind {
    case .localBranch:
      return "Delete local branch \(ref.shortName)."
    case .remoteBranch:
      return "Delete remote branch \(ref.shortName)."
    case .tag:
      return "Delete tag \(ref.shortName)."
    }
  }
  var detail: String {
    switch ref.kind {
    case .localBranch:
      return "The branch reference will be removed from this repository."
    case .remoteBranch:
      return "The branch reference will be deleted from its remote."
    case .tag:
      return "The tag reference will be removed from this repository."
    }
  }
}

struct ForcePushRequest: Identifiable, Hashable {
  var branch: GitRef

  var id: String { branch.id }
  var upstream: String { branch.upstream ?? "" }
  var title: String { "Force push with lease" }
  var message: String { "Force push \(branch.shortName)." }
  var detail: String { "Update \(upstream) only if the remote has not changed." }
}

struct DiscardChangeRequest: Identifiable, Hashable {
  var entry: GitStatusEntry

  var id: String { entry.id }
}

struct GitIgnoreTemplateRequest: Identifiable, Hashable {
  var repositoryName: String
  var templates: [GitIgnoreTemplate]

  var id: String { repositoryName }
  var title: String { "Add .gitignore template" }
}

enum DiscardPatchTarget: Hashable {
  case hunk(DiffHunk)
  case line(DiffLineChange)
}

struct DiscardPatchRequest: Identifiable, Hashable {
  var target: DiscardPatchTarget
  var path: String

  var id: String {
    switch target {
    case let .hunk(hunk):
      return "hunk:\(path):\(hunk.id)"
    case let .line(change):
      return "line:\(path):\(change.id)"
    }
  }

  var title: String {
    switch target {
    case .hunk:
      return "Discard hunk"
    case .line:
      return "Discard line change"
    }
  }

  var message: String {
    switch target {
    case let .hunk(hunk):
      return "Discard hunk \(hunk.id + 1) in \(path)."
    case let .line(change):
      return "Discard \(change.discardDescription) in \(path)."
    }
  }

  var detail: String {
    switch target {
    case .hunk:
      return "Only this unstaged hunk will be restored from Git."
    case .line:
      return "Only this unstaged line block will be restored from Git."
    }
  }
}

struct ApplyPatchRequest: Identifiable, Hashable {
  var patch: String

  var id: Int { patch.hashValue }
  var title: String { "Apply patch" }
  var message: String { "Apply patch from clipboard." }
  var previewText: String {
    let lines = patch.split(separator: "\n", omittingEmptySubsequences: false)
    let preview = lines.prefix(12).joined(separator: "\n")
    return lines.count > 12 ? "\(preview)\n..." : preview
  }
  var detail: String {
    let lines = patch.split(separator: "\n", omittingEmptySubsequences: false).count
    return "\(lines.formatted()) lines"
  }
}

struct DropStashRequest: Identifiable, Hashable {
  var stash: GitStash

  var id: String { stash.id }
  var title: String { "Drop stash" }
  var message: String { "Drop \(stash.index)." }
  var detail: String {
    stash.message.isEmpty ? "The stash entry will be removed." : stash.message
  }
}

struct RemoveRemoteRequest: Identifiable, Hashable {
  var remote: GitRemote

  var id: String { remote.id }
  var title: String { "Remove remote" }
  var message: String { "Remove remote \(remote.name)." }
  var detail: String {
    remote.fetchURL ?? remote.pushURL ?? "The remote configuration will be removed."
  }
}

struct RemoteTagDeleteRequest: Identifiable, Hashable {
  var tag: GitRef
  var remote: GitRemote

  var id: String { "\(remote.id):\(tag.id)" }
  var title: String { "Delete remote tag" }
  var message: String { "Delete tag \(tag.shortName) from \(remote.name)." }
  var detail: String { "The local tag will remain in this repository." }
}

struct RemoveWorktreeRequest: Identifiable, Hashable {
  var worktree: GitWorktree

  var id: String { worktree.id }
  var title: String { "Remove worktree" }
  var message: String { "Remove worktree \(worktree.name)." }
  var detail: String { worktree.path }
}

struct CreateWorktreeRequest: Identifiable, Hashable {
  var startPointTitle: String
  var defaultPath: String

  var id: String { startPointTitle }
  var title: String { "Create worktree" }
  var message: String { "Create a worktree from \(startPointTitle)." }
}

enum RemoteEditorMode: String, Identifiable {
  case add
  case edit

  var id: String { rawValue }
  var title: String { self == .add ? "Add remote" : "Edit remote" }
  var primaryActionTitle: String { self == .add ? "Add" : "Save" }
}

struct RemoteEditorRequest: Identifiable, Hashable {
  var mode: RemoteEditorMode
  var originalName: String?
  var name: String
  var url: String

  var id: String { "\(mode.rawValue):\(originalName ?? name)" }
}

enum GitFlowStartKind: String, CaseIterable, Identifiable {
  case feature
  case release
  case hotfix

  var id: String { rawValue }
  var title: String { rawValue.capitalized }

  func operationKind(action: GitFlowAction) -> GitOperationKind {
    switch (action, self) {
    case (.start, .feature):
      return .gitFlowFeatureStart
    case (.start, .release):
      return .gitFlowReleaseStart
    case (.start, .hotfix):
      return .gitFlowHotfixStart
    case (.finish, .feature):
      return .gitFlowFeatureFinish
    case (.finish, .release):
      return .gitFlowReleaseFinish
    case (.finish, .hotfix):
      return .gitFlowHotfixFinish
    }
  }
}

enum GitFlowAction: String {
  case start
  case finish

  var title: String { rawValue.capitalized }
}

enum RepositoryAction: String {
  case fetch = "Fetch"
  case pull = "Pull"
  case push = "Push"
}

enum GitOperationKind: String, Identifiable {
  case createBranch
  case renameBranch
  case createTag
  case renameTag
  case stashPush
  case stashPushIncludeUntracked
  case stashBranch
  case bisectStart
  case gitFlowFeatureStart
  case gitFlowReleaseStart
  case gitFlowHotfixStart
  case gitFlowFeatureFinish
  case gitFlowReleaseFinish
  case gitFlowHotfixFinish

  var id: String { rawValue }

  var allowsEmptyInput: Bool {
    self == .stashPush || self == .stashPushIncludeUntracked
  }
}

struct GitOperationRequest: Identifiable {
  var id = UUID()
  var kind: GitOperationKind
  var title: String
  var message: String
  var placeholder: String
  var defaultValue: String
  var primaryActionTitle: String
}

enum RepositorySetupMode: String, Identifiable {
  case clone
  case create

  var id: String { rawValue }
  var title: String { self == .clone ? "Clone repository" : "Create repository" }
  var primaryActionTitle: String { self == .clone ? "Clone" : "Create" }
}

enum MainMode: String, CaseIterable, Identifiable {
  case history = "History"
  case changes = "Changes"

  var id: String { rawValue }
}
