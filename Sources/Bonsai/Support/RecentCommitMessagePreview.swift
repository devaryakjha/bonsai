import Foundation

enum RecentCommitMessagePreview {
  static let maxLength = 72
  private static let ellipsis = "…"

  static func title(for message: String) -> String {
    let firstLine = message
      .split(whereSeparator: \.isNewline)
      .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
      .first { !$0.isEmpty } ?? message.trimmingCharacters(in: .whitespacesAndNewlines)

    guard firstLine.count > maxLength else {
      return firstLine
    }

    let endIndex = firstLine.index(firstLine.startIndex, offsetBy: maxLength - ellipsis.count)
    return String(firstLine[..<endIndex]) + ellipsis
  }
}
