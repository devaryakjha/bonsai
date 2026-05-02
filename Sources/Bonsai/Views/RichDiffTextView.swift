import AppKit
import SwiftUI

struct RichDiffTextView: NSViewRepresentable {
  var text: String
  var searchText: String = ""

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.backgroundColor = .windowBackgroundColor

    let textView = NSTextView()
    textView.isEditable = false
    textView.isSelectable = true
    textView.isRichText = false
    textView.usesFindBar = true
    textView.drawsBackground = true
    textView.backgroundColor = .windowBackgroundColor
    textView.textContainerInset = NSSize(width: 18, height: 16)
    textView.textContainer?.widthTracksTextView = false
    textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.minSize = NSSize(width: 0, height: 0)
    textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.isHorizontallyResizable = true
    textView.isVerticallyResizable = true
    textView.autoresizingMask = [.width]

    scrollView.documentView = textView
    context.coordinator.textView = textView
    updateNSView(scrollView, context: context)
    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard context.coordinator.lastText != text || context.coordinator.lastSearchText != searchText else { return }
    context.coordinator.lastText = text
    context.coordinator.lastSearchText = searchText
    context.coordinator.textView?.textStorage?.setAttributedString(Self.attributedDiff(text, searchText: searchText))
  }

  final class Coordinator {
    weak var textView: NSTextView?
    var lastText: String?
    var lastSearchText: String?
  }

  private static func attributedDiff(_ text: String, searchText: String) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let baseFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    paragraph.lineSpacing = 1

    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let isGitDiff = lines.contains { $0.hasPrefix("diff --git ") }
    for index in lines.indices {
      let line = lines[index]
      guard !isHiddenPatchMetadata(line, inGitDiff: isGitDiff) else { continue }
      var attributes: [NSAttributedString.Key: Any] = [
        .font: baseFont,
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: paragraph
      ]

      if line.hasPrefix("+") && !line.hasPrefix("+++") {
        attributes[.foregroundColor] = NSColor.systemGreen
        attributes[.backgroundColor] = NSColor.systemGreen.withAlphaComponent(0.10)
      } else if line.hasPrefix("-") && !line.hasPrefix("---") {
        attributes[.foregroundColor] = NSColor.systemRed
        attributes[.backgroundColor] = NSColor.systemRed.withAlphaComponent(0.10)
      } else if line.hasPrefix("@@") {
        attributes[.foregroundColor] = NSColor.systemBlue
        attributes[.backgroundColor] = NSColor.systemBlue.withAlphaComponent(0.08)
      }

      let lineString = NSMutableAttributedString(string: line + "\n", attributes: attributes)
      if let inlineRange = inlineRange(for: line, at: index, in: lines, diffLineCount: lines.count) {
        let highlightColor = line.hasPrefix("+")
          ? NSColor.systemGreen.withAlphaComponent(0.24)
          : NSColor.systemRed.withAlphaComponent(0.24)
        lineString.addAttribute(.backgroundColor, value: highlightColor, range: inlineRange)
      }
      applySearchHighlights(to: lineString, line: line, searchText: searchText, lineCount: lines.count)
      result.append(lineString)
    }
    return result
  }

  private static func isHiddenPatchMetadata(_ line: String, inGitDiff: Bool) -> Bool {
    DiffSearch.isHiddenPatchMetadata(line, inGitDiff: inGitDiff)
  }

  private static func inlineRange(for line: String, at index: Int, in lines: [String], diffLineCount: Int) -> NSRange? {
    guard line.hasPrefix("+") || line.hasPrefix("-"),
          !line.hasPrefix("+++") && !line.hasPrefix("---") else {
      return nil
    }

    let oldLine: String
    let newLine: String
    let isAddition = line.hasPrefix("+")
    if isAddition {
      guard index > 0, lines[index - 1].hasPrefix("-"), !lines[index - 1].hasPrefix("---") else { return nil }
      oldLine = String(lines[index - 1].dropFirst())
      newLine = String(line.dropFirst())
    } else {
      guard lines.indices.contains(index + 1), lines[index + 1].hasPrefix("+"), !lines[index + 1].hasPrefix("+++") else { return nil }
      oldLine = String(line.dropFirst())
      newLine = String(lines[index + 1].dropFirst())
    }
    guard DiffRenderPolicy.allowsInlineHighlight(oldLine: oldLine, newLine: newLine, diffLineCount: diffLineCount) else { return nil }

    let ranges = DiffInlineHighlighter.changedRanges(old: oldLine, new: newLine)
    let content = isAddition ? newLine : oldLine
    let range = isAddition ? ranges.newRange : ranges.oldRange
    guard let range else { return nil }
    let lower = content.distance(from: content.startIndex, to: range.lowerBound) + 1
    let length = content.distance(from: range.lowerBound, to: range.upperBound)
    return NSRange(location: lower, length: length)
  }

  private static func applySearchHighlights(
    to lineString: NSMutableAttributedString,
    line: String,
    searchText: String,
    lineCount: Int
  ) {
    guard lineCount <= DiffRenderPolicy.maxSearchHighlightLineCount else { return }
    let ranges = DiffSearch.ranges(in: line, query: searchText)
    guard !ranges.isEmpty else { return }

    let highlightColor = NSColor.systemYellow.withAlphaComponent(0.38)
    for range in ranges where NSMaxRange(range) <= lineString.length {
      lineString.addAttributes([
        .backgroundColor: highlightColor,
        .underlineStyle: NSUnderlineStyle.single.rawValue
      ], range: range)
    }
  }

}
