import AppKit
import SwiftUI

struct SplitDiffTextView: NSViewRepresentable {
  var splitDiff: SplitDiff
  var paneContext: SplitDiffPaneContext = .fallback

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> NSSplitView {
    let splitView = NSSplitView()
    splitView.isVertical = true
    splitView.dividerStyle = .thin

    let oldPane = Self.makePane(descriptor: paneContext.old)
    let newPane = Self.makePane(descriptor: paneContext.new)
    splitView.addArrangedSubview(oldPane.container)
    splitView.addArrangedSubview(newPane.container)

    context.coordinator.oldTextView = oldPane.textView
    context.coordinator.newTextView = newPane.textView
    context.coordinator.oldScrollView = oldPane.scrollView
    context.coordinator.newScrollView = newPane.scrollView
    context.coordinator.oldTitleLabel = oldPane.titleLabel
    context.coordinator.oldDetailLabel = oldPane.detailLabel
    context.coordinator.newTitleLabel = newPane.titleLabel
    context.coordinator.newDetailLabel = newPane.detailLabel
    context.coordinator.installScrollSync()

    updateNSView(splitView, context: context)
    return splitView
  }

  func updateNSView(_ splitView: NSSplitView, context: Context) {
    context.coordinator.setInitialDividerPositionIfNeeded(in: splitView)
    context.coordinator.updatePaneContextIfNeeded(paneContext)
    guard context.coordinator.lastDiff != splitDiff else { return }
    context.coordinator.lastDiff = splitDiff
    context.coordinator.oldTextView?.textStorage?.setAttributedString(Self.attributedDiff(
      splitDiff.oldLines,
      counterpart: splitDiff.newLines,
      side: .old,
      numberWidth: splitDiff.gutterNumberWidth
    ))
    context.coordinator.newTextView?.textStorage?.setAttributedString(Self.attributedDiff(
      splitDiff.newLines,
      counterpart: splitDiff.oldLines,
      side: .new,
      numberWidth: splitDiff.gutterNumberWidth
    ))
  }

  final class Coordinator {
    weak var oldTextView: NSTextView?
    weak var newTextView: NSTextView?
    weak var oldScrollView: NSScrollView?
    weak var newScrollView: NSScrollView?
    weak var oldTitleLabel: NSTextField?
    weak var oldDetailLabel: NSTextField?
    weak var newTitleLabel: NSTextField?
    weak var newDetailLabel: NSTextField?
    var lastDiff: SplitDiff?
    private var lastPaneContext: SplitDiffPaneContext?
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

    func updatePaneContextIfNeeded(_ paneContext: SplitDiffPaneContext) {
      guard lastPaneContext != paneContext else { return }
      lastPaneContext = paneContext
      updateHeader(
        titleLabel: oldTitleLabel,
        detailLabel: oldDetailLabel,
        descriptor: paneContext.old
      )
      updateHeader(
        titleLabel: newTitleLabel,
        detailLabel: newDetailLabel,
        descriptor: paneContext.new
      )
    }

    private func updateHeader(
      titleLabel: NSTextField?,
      detailLabel: NSTextField?,
      descriptor: SplitDiffPaneDescriptor
    ) {
      titleLabel?.stringValue = descriptor.title
      detailLabel?.stringValue = descriptor.detail ?? ""
      detailLabel?.isHidden = descriptor.detail == nil
      detailLabel?.toolTip = descriptor.detail
    }
  }

  private static func makePane(
    descriptor: SplitDiffPaneDescriptor
  ) -> (
    container: NSStackView,
    scrollView: NSScrollView,
    textView: NSTextView,
    titleLabel: NSTextField,
    detailLabel: NSTextField
  ) {
    let container = NSStackView()
    container.orientation = .vertical
    container.alignment = .width
    container.distribution = .fill
    container.spacing = 0

    let header = makeHeader(descriptor: descriptor)
    header.view.heightAnchor.constraint(equalToConstant: 30).isActive = true

    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.backgroundColor = .textBackgroundColor
    scrollView.contentView.postsBoundsChangedNotifications = true

    let textView = NSTextView()
    textView.isEditable = false
    textView.isSelectable = true
    textView.isRichText = false
    textView.usesFindBar = true
    textView.drawsBackground = true
    textView.backgroundColor = .textBackgroundColor
    textView.textContainerInset = NSSize(width: 18, height: 16)
    textView.textContainer?.widthTracksTextView = false
    textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.minSize = NSSize(width: 0, height: 0)
    textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.isHorizontallyResizable = true
    textView.isVerticallyResizable = true
    textView.autoresizingMask = [.width]

    scrollView.documentView = textView
    container.addArrangedSubview(header.view)
    container.addArrangedSubview(scrollView)
    return (container, scrollView, textView, header.titleLabel, header.detailLabel)
  }

  private static func makeHeader(
    descriptor: SplitDiffPaneDescriptor
  ) -> (view: NSView, titleLabel: NSTextField, detailLabel: NSTextField) {
    let material = NSVisualEffectView()
    material.material = .headerView
    material.blendingMode = .withinWindow
    material.state = .active

    let stack = NSStackView()
    stack.orientation = .horizontal
    stack.alignment = .centerY
    stack.spacing = 6
    stack.translatesAutoresizingMaskIntoConstraints = false

    if let image = NSImage(systemSymbolName: descriptor.systemImage, accessibilityDescription: descriptor.title) {
      let imageView = NSImageView(image: image)
      imageView.contentTintColor = .secondaryLabelColor
      imageView.translatesAutoresizingMaskIntoConstraints = false
      imageView.widthAnchor.constraint(equalToConstant: 14).isActive = true
      stack.addArrangedSubview(imageView)
    }

    let label = NSTextField(labelWithString: descriptor.title)
    label.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
    label.textColor = .secondaryLabelColor
    stack.addArrangedSubview(label)

    let detailLabel = NSTextField(labelWithString: descriptor.detail ?? "")
    detailLabel.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
    detailLabel.textColor = .tertiaryLabelColor
    detailLabel.lineBreakMode = .byTruncatingMiddle
    detailLabel.maximumNumberOfLines = 1
    detailLabel.isHidden = descriptor.detail == nil
    detailLabel.toolTip = descriptor.detail
    detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    stack.addArrangedSubview(detailLabel)

    material.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: material.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: material.trailingAnchor, constant: -12),
      stack.centerYAnchor.constraint(equalTo: material.centerYAnchor)
    ])
    return (material, label, detailLabel)
  }

  private enum SplitSide {
    case old
    case new
  }

  private static func attributedDiff(
    _ lines: [SplitDiffLine],
    counterpart: [SplitDiffLine],
    side: SplitSide,
    numberWidth: Int
  ) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let baseFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    paragraph.lineSpacing = 1

    for index in lines.indices {
      let line = lines[index].text
      let counterpartLine = counterpart.indices.contains(index) ? counterpart[index].text : ""
      let renderedLine = renderLine(lines[index], numberWidth: numberWidth, counterpart: counterpartLine)
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
      } else if line.isEmpty && !counterpartLine.isEmpty {
        attributes[.backgroundColor] = placeholderColor(for: counterpartLine)
      }

      let lineString = NSMutableAttributedString(string: renderedLine.text + "\n", attributes: attributes)
      let gutterRange = NSRange(location: 0, length: renderedLine.contentOffset)
      lineString.addAttributes([
        .foregroundColor: NSColor.tertiaryLabelColor,
        .backgroundColor: NSColor.textBackgroundColor.withAlphaComponent(0.35)
      ], range: gutterRange)

      if let inlineRange = inlineRange(
        for: line,
        counterpart: counterpartLine,
        side: side,
        contentOffset: renderedLine.contentOffset,
        diffLineCount: lines.count
      ) {
        let highlightColor = side == .new
          ? NSColor.systemGreen.withAlphaComponent(0.24)
          : NSColor.systemRed.withAlphaComponent(0.24)
        lineString.addAttribute(.backgroundColor, value: highlightColor, range: inlineRange)
      }
      result.append(lineString)
    }
    return result
  }

  private static func renderLine(_ line: SplitDiffLine, numberWidth: Int, counterpart: String) -> (text: String, contentOffset: Int) {
    let number = line.number.map { String($0).leftPadded(to: numberWidth) } ?? String(repeating: " ", count: numberWidth)
    if line.text.isEmpty && !counterpart.isEmpty {
      let prefix = "\(number)   │ "
      let placeholder = String(repeating: " ", count: DiffRenderPolicy.placeholderColumns(for: SplitDiffLine(number: nil, text: counterpart).displayText))
      return (prefix + placeholder, prefix.count)
    }
    let prefix = "\(number) \(line.changeMarker) │ "
    return (prefix + line.displayText, prefix.count)
  }

  private static func placeholderColor(for counterpart: String) -> NSColor {
    if counterpart.hasPrefix("+") {
      return NSColor.systemGreen.withAlphaComponent(0.055)
    }
    if counterpart.hasPrefix("-") {
      return NSColor.systemRed.withAlphaComponent(0.055)
    }
    return NSColor.textBackgroundColor.withAlphaComponent(0.35)
  }

  private static func inlineRange(
    for line: String,
    counterpart: String,
    side: SplitSide,
    contentOffset: Int,
    diffLineCount: Int
  ) -> NSRange? {
    switch side {
    case .old:
      guard line.hasPrefix("-"), counterpart.hasPrefix("+") else { return nil }
      let oldLine = String(line.dropFirst())
      let newLine = String(counterpart.dropFirst())
      guard DiffRenderPolicy.allowsInlineHighlight(oldLine: oldLine, newLine: newLine, diffLineCount: diffLineCount) else { return nil }
      guard let range = DiffInlineHighlighter.changedRanges(old: oldLine, new: newLine).oldRange else { return nil }
      return nsRange(for: range, in: oldLine, markerOffset: contentOffset)
    case .new:
      guard line.hasPrefix("+"), counterpart.hasPrefix("-") else { return nil }
      let oldLine = String(counterpart.dropFirst())
      let newLine = String(line.dropFirst())
      guard DiffRenderPolicy.allowsInlineHighlight(oldLine: oldLine, newLine: newLine, diffLineCount: diffLineCount) else { return nil }
      guard let range = DiffInlineHighlighter.changedRanges(old: oldLine, new: newLine).newRange else { return nil }
      return nsRange(for: range, in: newLine, markerOffset: contentOffset)
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
