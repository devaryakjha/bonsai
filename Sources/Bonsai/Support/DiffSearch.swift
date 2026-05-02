import Foundation

enum DiffSearch {
  static func visibleUnifiedText(from text: String) -> String {
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let isGitDiff = lines.contains { $0.hasPrefix("diff --git ") }
    return lines
      .filter { !isHiddenPatchMetadata($0, inGitDiff: isGitDiff) }
      .joined(separator: "\n")
  }

  static func visibleSplitText(from splitDiff: SplitDiff) -> String {
    (splitDiff.oldLines + splitDiff.newLines)
      .map(\.displayText)
      .joined(separator: "\n")
  }

  static func isHiddenPatchMetadata(_ line: String, inGitDiff: Bool) -> Bool {
    guard inGitDiff else { return false }
    return line.hasPrefix("diff --git ")
      || line.hasPrefix("index ")
      || line.hasPrefix("--- ")
      || line.hasPrefix("+++ ")
  }

  static func normalizedQuery(_ query: String) -> String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static func matchCount(in text: String, query: String) -> Int {
    ranges(in: text, query: query).count
  }

  static func matchLabel(for count: Int, query: String) -> String? {
    guard !normalizedQuery(query).isEmpty else { return nil }
    if count == 0 {
      return "No matches"
    }
    return count == 1 ? "1 match" : "\(count.formatted()) matches"
  }

  static func ranges(in text: String, query: String, limit: Int? = nil) -> [NSRange] {
    let query = normalizedQuery(query)
    guard !query.isEmpty, !text.isEmpty else { return [] }

    let haystack = text as NSString
    var ranges: [NSRange] = []
    var searchRange = NSRange(location: 0, length: haystack.length)

    while searchRange.length > 0 {
      let found = haystack.range(
        of: query,
        options: [.caseInsensitive, .diacriticInsensitive],
        range: searchRange
      )
      guard found.location != NSNotFound else { break }

      ranges.append(found)
      if let limit, ranges.count >= limit {
        break
      }

      let nextLocation = found.location + max(found.length, 1)
      guard nextLocation < haystack.length else { break }
      searchRange = NSRange(location: nextLocation, length: haystack.length - nextLocation)
    }

    return ranges
  }
}
