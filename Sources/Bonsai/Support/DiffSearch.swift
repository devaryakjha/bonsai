import Foundation

enum DiffSearch {
  struct MatchSummary: Equatable {
    var count: Int
    var isLimited: Bool

    static let empty = MatchSummary(count: 0, isLimited: false)
  }

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
    matchCount(in: text, normalizedQuery: normalizedQuery(query), limit: nil)
  }

  static func matchLabel(for count: Int, query: String) -> String? {
    matchLabel(for: MatchSummary(count: count, isLimited: false), query: query)
  }

  static func matchLabel(for summary: MatchSummary, query: String) -> String? {
    guard !normalizedQuery(query).isEmpty else { return nil }
    if summary.count == 0 {
      return "No matches"
    }
    let count = summary.count.formatted()
    if summary.isLimited {
      return "\(count)+ matches"
    }
    return summary.count == 1 ? "1 match" : "\(count) matches"
  }

  static func matchLabel(query: String, visibleText: () -> String) -> String? {
    guard !normalizedQuery(query).isEmpty else { return nil }
    return matchLabel(for: matchCount(in: visibleText(), query: query), query: query)
  }

  static func matchLabel(query: String, visibleMatchSummary: () -> MatchSummary) -> String? {
    guard !normalizedQuery(query).isEmpty else { return nil }
    return matchLabel(for: visibleMatchSummary(), query: query)
  }

  static func visibleUnifiedMatchSummary(
    from text: String,
    query: String,
    limit: Int = DiffRenderPolicy.maxFindMatchCount
  ) -> MatchSummary {
    let query = normalizedQuery(query)
    guard !query.isEmpty else { return .empty }

    let isGitDiff = text.hasPrefix("diff --git ")
      || text.range(of: "\ndiff --git ") != nil
    var summary = MatchSummary.empty

    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = String(line)
      guard !isHiddenPatchMetadata(line, inGitDiff: isGitDiff) else { continue }
      addMatches(in: line, normalizedQuery: query, limit: limit, to: &summary)
      if summary.isLimited {
        break
      }
    }

    return summary
  }

  static func visibleSplitMatchSummary(
    from splitDiff: SplitDiff,
    query: String,
    limit: Int = DiffRenderPolicy.maxFindMatchCount
  ) -> MatchSummary {
    let query = normalizedQuery(query)
    guard !query.isEmpty else { return .empty }

    var summary = MatchSummary.empty
    for line in splitDiff.oldLines {
      addMatches(in: line.displayText, normalizedQuery: query, limit: limit, to: &summary)
      if summary.isLimited {
        return summary
      }
    }
    for line in splitDiff.newLines {
      addMatches(in: line.displayText, normalizedQuery: query, limit: limit, to: &summary)
      if summary.isLimited {
        return summary
      }
    }

    return summary
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

  private static func addMatches(
    in text: String,
    normalizedQuery query: String,
    limit: Int,
    to summary: inout MatchSummary
  ) {
    let limit = max(1, limit)
    let remainingLimit = max(0, limit - summary.count)
    guard remainingLimit > 0 else {
      summary.isLimited = true
      return
    }

    let lineCount = matchCount(in: text, normalizedQuery: query, limit: remainingLimit)
    summary.count += lineCount
    if summary.count >= limit {
      summary.isLimited = true
    }
  }

  private static func matchCount(in text: String, normalizedQuery query: String, limit: Int?) -> Int {
    guard !query.isEmpty, !text.isEmpty else { return 0 }

    let haystack = text as NSString
    var count = 0
    var searchRange = NSRange(location: 0, length: haystack.length)

    while searchRange.length > 0 {
      let found = haystack.range(
        of: query,
        options: [.caseInsensitive, .diacriticInsensitive],
        range: searchRange
      )
      guard found.location != NSNotFound else { break }

      count += 1
      if let limit, count >= limit {
        break
      }

      let nextLocation = found.location + max(found.length, 1)
      guard nextLocation < haystack.length else { break }
      searchRange = NSRange(location: nextLocation, length: haystack.length - nextLocation)
    }

    return count
  }
}
