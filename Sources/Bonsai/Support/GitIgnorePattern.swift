import Foundation

enum GitIgnorePattern {
  static func repositoryRootPattern(for path: String) -> String {
    let normalized = path.split(separator: "/", omittingEmptySubsequences: true).joined(separator: "/")
    return "/\(normalized)"
  }

  static func extensionPattern(for path: String) -> String? {
    let fileName = path.split(separator: "/").last.map(String.init) ?? path
    guard let dotIndex = fileName.lastIndex(of: "."),
          dotIndex != fileName.startIndex,
          dotIndex < fileName.index(before: fileName.endIndex) else {
      return nil
    }
    return "*\(fileName[dotIndex...])"
  }

  static func directoryPattern(for path: String) -> String? {
    var components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    guard components.count > 1 else { return nil }
    _ = components.popLast()
    return "/\(components.joined(separator: "/"))/"
  }
}
