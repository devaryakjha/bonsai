import Foundation

enum CommitFilter {
  static func filter(_ commits: [GitCommit], query: String) -> [GitCommit] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return commits }
    let needle = trimmed.localizedLowercase

    return commits.filter { commit in
      commit.hash.localizedLowercase.contains(needle)
        || commit.shortHash.localizedLowercase.contains(needle)
        || commit.subject.localizedLowercase.contains(needle)
        || commit.authorName.localizedLowercase.contains(needle)
        || commit.authorEmail.localizedLowercase.contains(needle)
        || commit.decorations.contains { $0.localizedLowercase.contains(needle) }
    }
  }
}
