import Foundation

enum DiffInlineHighlighter {
  struct ChangedRanges: Hashable {
    var oldRanges: [Range<String.Index>]
    var newRanges: [Range<String.Index>]

    var oldRange: Range<String.Index>? {
      oldRanges.first
    }

    var newRange: Range<String.Index>? {
      newRanges.first
    }
  }

  static func changedRanges(old: String, new: String) -> ChangedRanges {
    let oldTokens = tokens(in: old)
    let newTokens = tokens(in: new)
    if oldTokens.count <= DiffRenderPolicy.maxInlineHighlightTokenCount,
       newTokens.count <= DiffRenderPolicy.maxInlineHighlightTokenCount {
      let tokenRanges = changedTokenRanges(oldTokens: oldTokens, newTokens: newTokens)
      if !tokenRanges.oldRanges.isEmpty || !tokenRanges.newRanges.isEmpty {
        return tokenRanges
      }
    }

    var oldStart = old.startIndex
    var newStart = new.startIndex
    var oldEnd = old.endIndex
    var newEnd = new.endIndex

    while oldStart < oldEnd, newStart < newEnd, old[oldStart] == new[newStart] {
      old.formIndex(after: &oldStart)
      new.formIndex(after: &newStart)
    }

    while oldStart < oldEnd, newStart < newEnd {
      let previousOld = old.index(before: oldEnd)
      let previousNew = new.index(before: newEnd)
      guard old[previousOld] == new[previousNew] else { break }
      oldEnd = previousOld
      newEnd = previousNew
    }

    return ChangedRanges(
      oldRanges: oldStart < oldEnd ? [oldStart..<oldEnd] : [],
      newRanges: newStart < newEnd ? [newStart..<newEnd] : []
    )
  }

  private struct Token: Hashable {
    var value: String
    var range: Range<String.Index>
  }

  private static func tokens(in line: String) -> [Token] {
    var tokens: [Token] = []
    var tokenStart: String.Index?
    var tokenKind: TokenKind?
    var index = line.startIndex

    while index < line.endIndex {
      let kind = TokenKind(character: line[index])
      if tokenKind != kind {
        if let tokenStart {
          tokens.append(Token(value: String(line[tokenStart..<index]), range: tokenStart..<index))
        }
        tokenStart = index
        tokenKind = kind
      }
      line.formIndex(after: &index)
    }

    if let tokenStart, tokenStart < line.endIndex {
      tokens.append(Token(value: String(line[tokenStart..<line.endIndex]), range: tokenStart..<line.endIndex))
    }
    return tokens
  }

  private enum TokenKind: Equatable {
    case word
    case whitespace
    case punctuation

    init(character: Character) {
      if character.isWhitespace {
        self = .whitespace
      } else if character.isLetter || character.isNumber || character == "_" {
        self = .word
      } else {
        self = .punctuation
      }
    }
  }

  private static func changedTokenRanges(oldTokens: [Token], newTokens: [Token]) -> ChangedRanges {
    let matches = lcsMatches(oldTokens.map(\.value), newTokens.map(\.value))
    var oldRanges: [Range<String.Index>] = []
    var newRanges: [Range<String.Index>] = []
    var oldCursor = 0
    var newCursor = 0

    for match in matches + [(oldTokens.count, newTokens.count)] {
      if oldCursor < match.0, let range = tokenRange(oldTokens[oldCursor..<match.0]) {
        oldRanges.append(range)
      }
      if newCursor < match.1, let range = tokenRange(newTokens[newCursor..<match.1]) {
        newRanges.append(range)
      }
      oldCursor = match.0 + 1
      newCursor = match.1 + 1
    }

    return ChangedRanges(oldRanges: oldRanges, newRanges: newRanges)
  }

  private static func tokenRange(_ tokens: ArraySlice<Token>) -> Range<String.Index>? {
    guard let first = tokens.first, let last = tokens.last else { return nil }
    return first.range.lowerBound..<last.range.upperBound
  }

  private static func lcsMatches(_ oldValues: [String], _ newValues: [String]) -> [(Int, Int)] {
    guard !oldValues.isEmpty, !newValues.isEmpty else { return [] }
    var lengths = Array(
      repeating: Array(repeating: 0, count: newValues.count + 1),
      count: oldValues.count + 1
    )

    for oldIndex in stride(from: oldValues.count - 1, through: 0, by: -1) {
      for newIndex in stride(from: newValues.count - 1, through: 0, by: -1) {
        if oldValues[oldIndex] == newValues[newIndex] {
          lengths[oldIndex][newIndex] = lengths[oldIndex + 1][newIndex + 1] + 1
        } else {
          lengths[oldIndex][newIndex] = max(lengths[oldIndex + 1][newIndex], lengths[oldIndex][newIndex + 1])
        }
      }
    }

    var matches: [(Int, Int)] = []
    var oldIndex = 0
    var newIndex = 0
    while oldIndex < oldValues.count, newIndex < newValues.count {
      if oldValues[oldIndex] == newValues[newIndex] {
        matches.append((oldIndex, newIndex))
        oldIndex += 1
        newIndex += 1
      } else if lengths[oldIndex + 1][newIndex] >= lengths[oldIndex][newIndex + 1] {
        oldIndex += 1
      } else {
        newIndex += 1
      }
    }
    return matches
  }
}
