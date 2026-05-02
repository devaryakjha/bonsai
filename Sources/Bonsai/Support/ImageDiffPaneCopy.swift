enum ImageDiffPaneSide {
  case before
  case after

  var title: String {
    switch self {
    case .before:
      return "Before"
    case .after:
      return "After"
    }
  }

  var missingTitle: String {
    switch self {
    case .before:
      return "No previous image"
    case .after:
      return "No new image"
    }
  }
}
