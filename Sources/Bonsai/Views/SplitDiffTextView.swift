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
    context.coordinator.oldTextView?.textStorage?.setAttributedString(Self.attributedDiff(splitDiff.oldText))
    context.coordinator.newTextView?.textStorage?.setAttributedString(Self.attributedDiff(splitDiff.newText))
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

  private static func attributedDiff(_ text: String) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let baseFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    paragraph.lineSpacing = 1

    for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
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

      result.append(NSAttributedString(string: line + "\n", attributes: attributes))
    }
    return result
  }
}
