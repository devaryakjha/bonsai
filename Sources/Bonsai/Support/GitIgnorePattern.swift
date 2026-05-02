import Foundation

enum GitIgnorePattern {
  static func repositoryRootPattern(for path: String) -> String {
    let normalized = path.split(separator: "/", omittingEmptySubsequences: true).joined(separator: "/")
    return "/\(normalized)"
  }
}
