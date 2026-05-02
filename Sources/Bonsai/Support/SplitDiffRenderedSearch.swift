import Foundation

enum SplitDiffRenderedSearch {
  struct RenderedLine: Equatable {
    var text: String
    var contentOffset: Int
    var isPlaceholder: Bool
  }

  static func renderLine(_ line: SplitDiffLine, numberWidth: Int, counterpart: String) -> RenderedLine {
    let number = line.number.map { String($0).leftPadded(to: numberWidth) } ?? String(repeating: " ", count: numberWidth)
    if line.text.isEmpty && !counterpart.isEmpty {
      let prefix = "\(number)   │ "
      let placeholder = DiffRenderPolicy.splitPlaceholder(counterpart: SplitDiffLine(number: nil, text: counterpart).displayText)
      return RenderedLine(text: prefix + placeholder, contentOffset: prefix.count, isPlaceholder: true)
    }

    let prefix = "\(number) \(line.changeMarker) │ "
    return RenderedLine(text: prefix + line.displayText, contentOffset: prefix.count, isPlaceholder: false)
  }

  static func ranges(
    in lines: [SplitDiffLine],
    counterpart: [SplitDiffLine],
    numberWidth: Int,
    query: String
  ) -> [NSRange] {
    guard !DiffSearch.normalizedQuery(query).isEmpty else { return [] }

    var ranges: [NSRange] = []
    var lineLocation = 0
    for index in lines.indices {
      let counterpartText = counterpart.indices.contains(index) ? counterpart[index].text : ""
      let renderedLine = renderLine(lines[index], numberWidth: numberWidth, counterpart: counterpartText)
      defer {
        lineLocation += ((renderedLine.text + "\n") as NSString).length
      }

      guard !renderedLine.isPlaceholder else { continue }
      let contentRanges = DiffSearch.ranges(in: lines[index].displayText, query: query)
      ranges.append(contentsOf: contentRanges.map { range in
        NSRange(location: lineLocation + renderedLine.contentOffset + range.location, length: range.length)
      })
    }

    return ranges
  }
}

private extension String {
  func leftPadded(to width: Int) -> String {
    guard count < width else { return self }
    return String(repeating: " ", count: width - count) + self
  }
}
