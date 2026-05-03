import Foundation

struct DiffSummary: Equatable {
  var additions = 0
  var deletions = 0
  var hunkCount = 0

  init(additions: Int = 0, deletions: Int = 0, hunkCount: Int = 0) {
    self.additions = additions
    self.deletions = deletions
    self.hunkCount = hunkCount
  }

  init(diffText: String, hunkCount: Int) {
    self.hunkCount = hunkCount
    for line in diffText.split(separator: "\n", omittingEmptySubsequences: false) {
      if line.hasPrefix("+") && !line.hasPrefix("+++") {
        additions += 1
      } else if line.hasPrefix("-") && !line.hasPrefix("---") {
        deletions += 1
      }
    }
  }

  var isEmpty: Bool {
    additions == 0 && deletions == 0 && hunkCount == 0
  }

  var isMetadataOnly: Bool {
    additions == 0 && deletions == 0
  }
}
