import Foundation

struct GitRepository: Identifiable, Hashable, Codable {
  var path: String

  var id: String { path }
  var name: String { URL(filePath: path).lastPathComponent }
}

struct WorkspaceGroup: Identifiable, Hashable {
  var name: String
  var repositories: [GitRepository]

  var id: String { name }
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
}

struct GitTreeEntry: Identifiable, Hashable {
  enum EntryKind: String {
    case tree
    case blob
    case commit
    case unknown
  }

  var mode: String
  var kind: EntryKind
  var object: String
  var path: String
  var name: String

  var id: String { "\(kind.rawValue):\(path)" }
  var isDirectory: Bool { kind == .tree }
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
      return "Gone"
    }
    if ahead == 0 && behind == 0 {
      return nil
    }
    var parts: [String] = []
    if ahead > 0 { parts.append("up \(ahead)") }
    if behind > 0 { parts.append("down \(behind)") }
    return parts.joined(separator: " ")
  }
  var pullTitle: String {
    behind > 0 ? "Pull \(behind)" : "Pull"
  }
  var pushTitle: String {
    ahead > 0 ? "Push \(ahead)" : "Push"
  }

  var remoteTrackingLocalName: String? {
    guard kind == .remoteBranch else { return nil }
    let parts = shortName.split(separator: "/", maxSplits: 1).map(String.init)
    guard parts.count == 2, parts[1] != "HEAD" else { return nil }
    return parts[1]
  }
}

struct GitRemote: Identifiable, Hashable {
  var name: String
  var fetchURL: String?
  var pushURL: String?

  var id: String { name }
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

enum GitHubRepositoryOperation: String, Identifiable {
  case create
  case delete

  var id: String { rawValue }
  var title: String { self == .create ? "Create GitHub Repository" : "Delete GitHub Repository" }
  var primaryActionTitle: String { self == .create ? "Create" : "Delete" }
}

struct GitHubRepositoryRequest: Identifiable, Hashable {
  var operation: GitHubRepositoryOperation
  var owner: String
  var name: String
  var repositoryDescription: String
  var isPrivate: Bool

  var id: String { operation.rawValue }
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
  case ours = "Accept Ours"
  case theirs = "Accept Theirs"
  case markResolved = "Mark Resolved"
}

struct ConflictResolutionRequest: Identifiable, Hashable {
  var entry: GitStatusEntry
  var preview: String

  var id: String { entry.id }
}

enum DiffAlgorithm: String, CaseIterable, Identifiable {
  case histogram
  case patience
  case myers
  case minimal

  var id: String { rawValue }
  var title: String { rawValue.capitalized }
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
}

struct SplitDiff: Hashable {
  var oldLines: [SplitDiffLine]
  var newLines: [SplitDiffLine]

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

  var todoText: String {
    items.map(\.todoLine).joined(separator: "\n") + "\n"
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

struct ResetRequest: Identifiable, Hashable {
  var commit: GitCommit
  var mode: ResetMode = .mixed

  var id: String { commit.hash }
}

struct ReflogResetRequest: Identifiable, Hashable {
  var entry: GitReflogEntry
  var mode: ResetMode = .mixed

  var id: String { entry.id }
}

struct DiscardChangeRequest: Identifiable, Hashable {
  var entry: GitStatusEntry

  var id: String { entry.id }
}

enum RemoteEditorMode: String, Identifiable {
  case add
  case edit

  var id: String { rawValue }
  var title: String { self == .add ? "Add Remote" : "Edit Remote" }
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
  case createWorktree
  case stashPush
  case stashPushIncludeUntracked
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
