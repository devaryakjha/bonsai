enum GitChangeStatusRole: String {
  case added
  case deleted
  case modified
  case renamed
  case copied
  case conflicted
  case untracked
  case ignored
  case unknown

  init(code: String) {
    switch code.first {
    case "A":
      self = .added
    case "D":
      self = .deleted
    case "M", "T":
      self = .modified
    case "R":
      self = .renamed
    case "C":
      self = .copied
    case "U":
      self = .conflicted
    case "?":
      self = .untracked
    case "!":
      self = .ignored
    default:
      self = .unknown
    }
  }

  var colorToken: GitChangeStatusColorToken {
    switch self {
    case .added:
      return .green
    case .deleted:
      return .red
    case .modified:
      return .amber
    case .renamed:
      return .purple
    case .copied:
      return .blue
    case .conflicted:
      return .orange
    case .untracked, .ignored, .unknown:
      return .neutral
    }
  }
}

enum GitChangeStatusColorToken: String {
  case green
  case red
  case amber
  case purple
  case blue
  case orange
  case neutral

  var conventionalName: String {
    switch self {
    case .green:
      return "green"
    case .red:
      return "red"
    case .amber:
      return "amber"
    case .purple:
      return "purple"
    case .blue:
      return "blue"
    case .orange:
      return "orange"
    case .neutral:
      return "neutral"
    }
  }
}

extension GitStatusEntry {
  var statusRole: GitChangeStatusRole {
    GitChangeStatusRole(code: statusCode)
  }
}

extension GitChangedFile {
  var statusRole: GitChangeStatusRole {
    GitChangeStatusRole(code: statusCode)
  }
}
