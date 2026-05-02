enum GitChangeStatusRole: String {
  case added
  case deleted
  case modified
  case renamed
  case copied
  case conflicted
  case untracked
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
    default:
      self = .unknown
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
