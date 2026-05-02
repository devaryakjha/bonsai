import Foundation

enum DiffInlineHighlighter {
  struct ChangedRanges: Hashable {
    var oldRange: Range<String.Index>?
    var newRange: Range<String.Index>?
  }

  static func changedRanges(old: String, new: String) -> ChangedRanges {
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
      oldRange: oldStart < oldEnd ? oldStart..<oldEnd : nil,
      newRange: newStart < newEnd ? newStart..<newEnd : nil
    )
  }
}
