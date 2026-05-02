import AppKit
import SwiftUI

struct SplitDiffTextView: NSViewRepresentable {
  var splitDiff: SplitDiff

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> NSSplitView {
    let splitView = NSSplitView()
    splitView.isVertical = true
    splitView.dividerStyle = .thin

    let oldPane = Self.makePane()
    let newPane = Self.makePane()
    splitView.addArrangedSubview(oldPane.scrollView)
    splitView.addArrangedSubview(newPane.scrollView)

    context.coordinator.oldTextView = oldPane.textView
    context.coordinator.newTextView = newPane.textView
    context.coordinator.oldScrollView = oldPane.scrollView
    context.coordinator.newScrollView = newPane.scrollView
    context.coordinator.installScrollSync()

    updateNSView(splitView, context: context)
    return splitView
  }

  func updateNSView(_ splitView: NSSplitView, context: Context) {
    context.coordinator.setInitialDividerPositionIfNeeded(in: splitView)
    guard context.coordinator.lastDiff != splitDiff else { return }
    context.coordinator.lastDiff = splitDiff
    context.coordinator.oldTextView?.textStorage?.setAttributedString(Self.attributedDiff(splitDiff.oldLines, counterpart: splitDiff.newLines, side: .old))
    context.coordinator.newTextView?.textStorage?.setAttributedString(Self.attributedDiff(splitDiff.newLines, counterpart: splitDiff.oldLines, side: .new))
  }

  final class Coordinator {
    weak var oldTextView: NSTextView?
    weak var newTextView: NSTextView?
    weak var oldScrollView: NSScrollView?
    weak var newScrollView: NSScrollView?
    var lastDiff: SplitDiff?
    private var didSetInitialDividerPosition = false
    private var isSyncing = false

    func setInitialDividerPositionIfNeeded(in splitView: NSSplitView) {
      guard !didSetInitialDividerPosition else { return }
      let width = splitView.bounds.width
      guard width > 0 else {
        DispatchQueue.main.async { [weak self, weak splitView] in
          guard let self, let splitView else { return }
          self.setInitialDividerPositionIfNeeded(in: splitView)
        }
        return
      }
      splitView.setPosition(width / 2, ofDividerAt: 0)
      didSetInitialDividerPosition = true
    }

    func installScrollSync() {
      if let oldClip = oldScrollView?.contentView {
        NotificationCenter.default.addObserver(
          forName: NSView.boundsDidChangeNotification,
          object: oldClip,
          queue: .main
        ) { [weak self] _ in
          self?.sync(from: self?.oldScrollView, to: self?.newScrollView)
        }
      }

      if let newClip = newScrollView?.contentView {
        NotificationCenter.default.addObserver(
          forName: NSView.boundsDidChangeNotification,
          object: newClip,
          queue: .main
        ) { [weak self] _ in
          self?.sync(from: self?.newScrollView, to: self?.oldScrollView)
        }
      }
    }

    private func sync(from source: NSScrollView?, to target: NSScrollView?) {
      guard !isSyncing,
            let source,
            let target else { return }
      isSyncing = true
      target.contentView.scroll(to: NSPoint(x: target.contentView.bounds.origin.x, y: source.contentView.bounds.origin.y))
      target.reflectScrolledClipView(target.contentView)
      isSyncing = false
    }
  }

  private static func makePane() -> (scrollView: NSScrollView, textView: NSTextView) {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.backgroundColor = .windowBackgroundColor
    scrollView.contentView.postsBoundsChangedNotifications = true

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
    return (scrollView, textView)
  }

  private enum SplitSide {
    case old
    case new
  }

  private static func attributedDiff(_ lines: [SplitDiffLine], counterpart: [SplitDiffLine], side: SplitSide) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let baseFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    paragraph.lineSpacing = 1

    let numberWidth = max(3, lines.compactMap(\.number).map { "\($0)".count }.max() ?? 3)
    for index in lines.indices {
      let line = lines[index].text
      let renderedLine = renderLine(lines[index], numberWidth: numberWidth)
      let contentOffset = renderedLine.count - line.count
      var attributes: [NSAttributedString.Key: Any] = [
        .font: baseFont,
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: paragraph
      ]

      if line.hasPrefix("+") {
        attributes[.foregroundColor] = NSColor.systemGreen
        attributes[.backgroundColor] = NSColor.systemGreen.withAlphaComponent(0.10)
      } else if line.hasPrefix("-") {
        attributes[.foregroundColor] = NSColor.systemRed
        attributes[.backgroundColor] = NSColor.systemRed.withAlphaComponent(0.10)
      } else if line.hasPrefix("@@") {
        attributes[.foregroundColor] = NSColor.systemBlue
        attributes[.backgroundColor] = NSColor.systemBlue.withAlphaComponent(0.08)
      }

      let lineString = NSMutableAttributedString(string: renderedLine + "\n", attributes: attributes)
      let gutterRange = NSRange(location: 0, length: contentOffset)
      lineString.addAttributes([
        .foregroundColor: NSColor.tertiaryLabelColor,
        .backgroundColor: NSColor.textBackgroundColor.withAlphaComponent(0.35)
      ], range: gutterRange)

      let counterpartLine = counterpart.indices.contains(index) ? counterpart[index].text : ""
      if let inlineRange = inlineRange(for: line, counterpart: counterpartLine, side: side, contentOffset: contentOffset) {
        let highlightColor = side == .new
          ? NSColor.systemGreen.withAlphaComponent(0.24)
          : NSColor.systemRed.withAlphaComponent(0.24)
        lineString.addAttribute(.backgroundColor, value: highlightColor, range: inlineRange)
      }
      result.append(lineString)
    }
    return result
  }

  private static func renderLine(_ line: SplitDiffLine, numberWidth: Int) -> String {
    let number = line.number.map { String($0).leftPadded(to: numberWidth) } ?? String(repeating: " ", count: numberWidth)
    return "\(number) │ \(line.text)"
  }

  private static func inlineRange(for line: String, counterpart: String, side: SplitSide, contentOffset: Int) -> NSRange? {
    switch side {
    case .old:
      guard line.hasPrefix("-"), counterpart.hasPrefix("+") else { return nil }
      let oldLine = String(line.dropFirst())
      let newLine = String(counterpart.dropFirst())
      guard let range = DiffInlineHighlighter.changedRanges(old: oldLine, new: newLine).oldRange else { return nil }
      return nsRange(for: range, in: oldLine, markerOffset: contentOffset + 1)
    case .new:
      guard line.hasPrefix("+"), counterpart.hasPrefix("-") else { return nil }
      let oldLine = String(counterpart.dropFirst())
      let newLine = String(line.dropFirst())
      guard let range = DiffInlineHighlighter.changedRanges(old: oldLine, new: newLine).newRange else { return nil }
      return nsRange(for: range, in: newLine, markerOffset: contentOffset + 1)
    }
  }

  private static func nsRange(for range: Range<String.Index>, in line: String, markerOffset: Int) -> NSRange {
    let lower = line.distance(from: line.startIndex, to: range.lowerBound) + markerOffset
    let length = line.distance(from: range.lowerBound, to: range.upperBound)
    return NSRange(location: lower, length: length)
  }
}

private extension String {
  func leftPadded(to width: Int) -> String {
    guard count < width else { return self }
    return String(repeating: " ", count: width - count) + self
  }
}
