import Foundation

struct DiffHunkHistoryRange: Equatable {
  var startLine: Int
  var endLine: Int

  var title: String {
    startLine == endLine ? "Line \(startLine)" : "Lines \(startLine)-\(endLine)"
  }

  static func range(for hunk: DiffHunk) -> DiffHunkHistoryRange? {
    range(fromHeader: hunk.header)
  }

  static func range(fromHeader header: String) -> DiffHunkHistoryRange? {
    let pieces = header.split(separator: " ")
    guard pieces.count >= 3,
          pieces[2].hasPrefix("+") else {
      return nil
    }

    let rangeText = pieces[2].dropFirst()
    let parts = rangeText.split(separator: ",", maxSplits: 1).map(String.init)
    guard let start = Int(parts[0]) else { return nil }
    let count = parts.count > 1 ? (Int(parts[1]) ?? 1) : 1
    let safeStart = max(start, 1)
    let safeCount = max(count, 1)
    return DiffHunkHistoryRange(startLine: safeStart, endLine: safeStart + safeCount - 1)
  }
}
