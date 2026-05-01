import Foundation

struct GitRepository: Identifiable, Hashable, Codable {
  var path: String

  var id: String { path }
  var name: String { URL(filePath: path).lastPathComponent }
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

struct RepositorySnapshot {
  var status: [GitStatusEntry] = []
  var commits: [GitCommit] = []
  var changedFiles: [GitChangedFile] = []
  var refs: [GitRef] = []
  var remotes: [GitRemote] = []
  var stashes: [GitStash] = []
  var submodules: [GitSubmodule] = []
}

struct CommandResult: Identifiable, Hashable {
  var id = UUID()
  var title: String
  var output: String
  var isError: Bool
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
