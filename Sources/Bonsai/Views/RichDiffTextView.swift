import AppKit
import SwiftUI

struct RichDiffTextView: NSViewRepresentable {
  var text: String

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
    guard context.coordinator.lastText != text else { return }
    context.coordinator.lastText = text
    context.coordinator.textView?.textStorage?.setAttributedString(Self.attributedDiff(text))
  }

  final class Coordinator {
    weak var textView: NSTextView?
    var lastText: String?
  }

  private static func attributedDiff(_ text: String) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let baseFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let metadataFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    paragraph.lineSpacing = 1

    for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
      guard !line.hasPrefix("index ") else { continue }
      let displayLine = displayText(for: line)
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
      } else if line.hasPrefix("diff --git") || line.hasPrefix("index ") || line.hasPrefix("---") || line.hasPrefix("+++") {
        attributes[.font] = metadataFont
        attributes[.foregroundColor] = NSColor.secondaryLabelColor
      }

      result.append(NSAttributedString(string: displayLine + "\n", attributes: attributes))
    }
    return result
  }

  private static func displayText(for line: String) -> String {
    if line.hasPrefix("diff --git") {
      let pieces = line.split(separator: " ")
      if let path = pieces.last {
        return "File " + cleanedPath(String(path), prefix: "b/")
      }
    }
    if line.hasPrefix("--- ") {
      return "Before " + cleanedPath(String(line.dropFirst(4)), prefix: "a/")
    }
    if line.hasPrefix("+++ ") {
      return "After  " + cleanedPath(String(line.dropFirst(4)), prefix: "b/")
    }
    return line
  }

  private static func cleanedPath(_ path: String, prefix: String) -> String {
    path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
  }
}
