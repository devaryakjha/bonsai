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

  var id: String { hash }
}

struct GitChangedFile: Identifiable, Hashable {
  var status: String
  var path: String
  var oldPath: String?

  var id: String { "\(status):\(oldPath ?? ""):\(path)" }
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
  var isHead: Bool
  var kind: RefKind

  var id: String { "\(kind.rawValue):\(name)" }
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

struct GitSubmodule: Identifiable, Hashable {
  var path: String
  var commit: String
  var status: String

  var id: String { path }
}

struct GitLFSFile: Identifiable, Hashable {
  var oid: String
  var path: String

  var id: String { path }
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
  var integrations = GitIntegrationStatus()
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

struct SplitDiff: Hashable {
  var oldText: String
  var newText: String
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
}

enum RepositoryAction: String {
  case fetch = "Fetch"
  case pull = "Pull"
  case push = "Push"
}

enum GitOperationKind: String, Identifiable {
  case createBranch
  case createTag
  case stashPush
  case gitFlowFeatureStart
  case gitFlowReleaseStart
  case gitFlowHotfixStart

  var id: String { rawValue }
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
  var title: String { self == .clone ? "Clone Repository" : "Create Repository" }
  var primaryActionTitle: String { self == .clone ? "Clone" : "Create" }
}

enum MainMode: String, CaseIterable, Identifiable {
  case history = "History"
  case changes = "Changes"

  var id: String { rawValue }
}
