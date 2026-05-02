import Foundation

enum DiffRenderPolicy {
  static let maxInlineComparableLength = 4_000
  static let maxInlineHighlightLineCount = 20_000
  static let maxSearchHighlightLineCount = 20_000
  static let minPlaceholderColumns = 24
  static let maxPlaceholderColumns = 160
  static let splitPlaceholderText = "No line"

  static func allowsInlineHighlight(oldLine: String, newLine: String, diffLineCount: Int? = nil) -> Bool {
    if let diffLineCount, diffLineCount > maxInlineHighlightLineCount {
      return false
    }
    return oldLine.count <= maxInlineComparableLength && newLine.count <= maxInlineComparableLength
  }

  static func placeholderColumns(for counterpart: String) -> Int {
    min(max(minPlaceholderColumns, counterpart.count), maxPlaceholderColumns)
  }

  static func splitPlaceholder(counterpart: String) -> String {
    let width = placeholderColumns(for: counterpart)
    guard splitPlaceholderText.count < width else { return splitPlaceholderText }
    return splitPlaceholderText + String(repeating: " ", count: width - splitPlaceholderText.count)
  }
}
