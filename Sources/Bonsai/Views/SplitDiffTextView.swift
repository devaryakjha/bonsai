import AppKit
import SwiftUI

struct SplitDiffTextView: NSViewRepresentable {
  var splitDiff: SplitDiff
  var renderVersion: Int?
  var paneContext: SplitDiffPaneContext = .fallback
  var searchText: String = ""
  var searchNavigationRequest: DiffSearch.NavigationRequest?

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
    context.coordinator.installFrameObserver(for: splitView)

    updateNSView(splitView, context: context)
    return splitView
  }

  func updateNSView(_ splitView: NSSplitView, context: Context) {
    context.coordinator.updateOrientationIfNeeded(in: splitView)
    context.coordinator.setDividerPositionIfNeeded(in: splitView)
    context.coordinator.updatePaneContextIfNeeded(paneContext)
    let shouldRender = context.coordinator.shouldRender(
      splitDiff: splitDiff,
      renderVersion: renderVersion,
      searchText: searchText
    )
    if shouldRender {
      context.coordinator.lastDiff = renderVersion == nil ? splitDiff : nil
      context.coordinator.lastRenderVersion = renderVersion
      context.coordinator.lastSearchText = searchText
      context.coordinator.oldTextView?.textStorage?.setAttributedString(Self.attributedDiff(
        splitDiff.oldLines,
        counterpart: splitDiff.newLines,
        side: .old,
        numberWidth: splitDiff.gutterNumberWidth,
        searchText: searchText
      ))
      context.coordinator.newTextView?.textStorage?.setAttributedString(Self.attributedDiff(
        splitDiff.newLines,
        counterpart: splitDiff.oldLines,
        side: .new,
        numberWidth: splitDiff.gutterNumberWidth,
        searchText: searchText
      ))
      context.coordinator.oldSearchRanges = SplitDiffRenderedSearch.ranges(
        in: splitDiff.oldLines,
        counterpart: splitDiff.newLines,
        numberWidth: splitDiff.gutterNumberWidth,
        query: searchText
      )
      context.coordinator.newSearchRanges = SplitDiffRenderedSearch.ranges(
        in: splitDiff.newLines,
        counterpart: splitDiff.oldLines,
        numberWidth: splitDiff.gutterNumberWidth,
        query: searchText
      )
    }

    guard context.coordinator.lastSearchNavigationRequest != searchNavigationRequest else { return }
    context.coordinator.lastSearchNavigationRequest = searchNavigationRequest
    context.coordinator.navigateSearch(query: searchText, request: searchNavigationRequest)
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
    var lastRenderVersion: Int?
    var lastSearchText: String?
    var lastSearchNavigationRequest: DiffSearch.NavigationRequest?
    var oldSearchRanges: [NSRange] = []
    var newSearchRanges: [NSRange] = []
    private var lastPaneContext: SplitDiffPaneContext?
    private var didSetInitialDividerPosition = false
    private var lastUsesSideBySide: Bool?
    private var isSyncing = false
    private var frameObserver: NSObjectProtocol?
    private var scrollObservers: [NSObjectProtocol] = []

    deinit {
      if let frameObserver {
        NotificationCenter.default.removeObserver(frameObserver)
      }
      for observer in scrollObservers {
        NotificationCenter.default.removeObserver(observer)
      }
    }

    func shouldRender(splitDiff: SplitDiff, renderVersion: Int?, searchText: String) -> Bool {
      if let renderVersion {
        return lastRenderVersion != renderVersion || lastSearchText != searchText
      }
      return lastDiff != splitDiff || lastSearchText != searchText
    }

    func installFrameObserver(for splitView: NSSplitView) {
      guard frameObserver == nil else { return }
      splitView.postsFrameChangedNotifications = true
      frameObserver = NotificationCenter.default.addObserver(
        forName: NSView.frameDidChangeNotification,
        object: splitView,
        queue: .main
      ) { [weak self, weak splitView] _ in
        guard let self, let splitView else { return }
        self.updateOrientationIfNeeded(in: splitView)
        self.setDividerPositionIfNeeded(in: splitView)
      }
    }

    func updateOrientationIfNeeded(in splitView: NSSplitView) {
      let usesSideBySide = SplitDiffLayoutPolicy.usesSideBySide(width: splitView.bounds.width)
      guard lastUsesSideBySide != usesSideBySide else { return }
      splitView.isVertical = usesSideBySide
      didSetInitialDividerPosition = false
      lastUsesSideBySide = usesSideBySide
    }

    func setDividerPositionIfNeeded(in splitView: NSSplitView) {
      guard !didSetInitialDividerPosition else { return }
      let length = splitView.isVertical ? splitView.bounds.width : splitView.bounds.height
      guard length > 0 else {
        DispatchQueue.main.async { [weak self, weak splitView] in
          guard let self, let splitView else { return }
          self.updateOrientationIfNeeded(in: splitView)
          self.setDividerPositionIfNeeded(in: splitView)
        }
        return
      }
      splitView.setPosition(length / 2, ofDividerAt: 0)
      didSetInitialDividerPosition = true
    }

    func installScrollSync() {
      if let oldClip = oldScrollView?.contentView {
        let observer = NotificationCenter.default.addObserver(
          forName: NSView.boundsDidChangeNotification,
          object: oldClip,
          queue: .main
        ) { [weak self] _ in
          self?.sync(from: self?.oldScrollView, to: self?.newScrollView)
        }
        scrollObservers.append(observer)
      }

      if let newClip = newScrollView?.contentView {
        let observer = NotificationCenter.default.addObserver(
          forName: NSView.boundsDidChangeNotification,
          object: newClip,
          queue: .main
        ) { [weak self] _ in
          self?.sync(from: self?.newScrollView, to: self?.oldScrollView)
        }
        scrollObservers.append(observer)
      }
    }

    private func sync(from source: NSScrollView?, to target: NSScrollView?) {
      guard !isSyncing,
            let source,
            let target else { return }
      let sourceY = source.contentView.bounds.origin.y
      let targetY = target.contentView.bounds.origin.y
      guard abs(sourceY - targetY) > 0.5 else { return }
      isSyncing = true
      target.contentView.scroll(to: NSPoint(x: target.contentView.bounds.origin.x, y: sourceY))
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

    func navigateSearch(query: String, request: DiffSearch.NavigationRequest?) {
      guard let request,
            !DiffSearch.normalizedQuery(query).isEmpty else { return }

      let activeTextView = NSApp.keyWindow?.firstResponder as? NSTextView
      let oldIsActive = activeTextView === oldTextView
      let newIsActive = activeTextView === newTextView

      switch request.direction {
      case .next:
        if oldIsActive {
          if selectMatch(in: oldTextView, ranges: oldSearchRanges, direction: .next, allowsWrap: false) { return }
          if selectEdgeMatch(in: newTextView, ranges: newSearchRanges, direction: .next) { return }
          _ = selectEdgeMatch(in: oldTextView, ranges: oldSearchRanges, direction: .next)
        } else if newIsActive {
          if selectMatch(in: newTextView, ranges: newSearchRanges, direction: .next, allowsWrap: false) { return }
          if selectEdgeMatch(in: oldTextView, ranges: oldSearchRanges, direction: .next) { return }
          _ = selectEdgeMatch(in: newTextView, ranges: newSearchRanges, direction: .next)
        } else {
          if selectEdgeMatch(in: oldTextView, ranges: oldSearchRanges, direction: .next) { return }
          _ = selectEdgeMatch(in: newTextView, ranges: newSearchRanges, direction: .next)
        }
      case .previous:
        if newIsActive {
          if selectMatch(in: newTextView, ranges: newSearchRanges, direction: .previous, allowsWrap: false) { return }
          if selectEdgeMatch(in: oldTextView, ranges: oldSearchRanges, direction: .previous) { return }
          _ = selectEdgeMatch(in: newTextView, ranges: newSearchRanges, direction: .previous)
        } else if oldIsActive {
          if selectMatch(in: oldTextView, ranges: oldSearchRanges, direction: .previous, allowsWrap: false) { return }
          if selectEdgeMatch(in: newTextView, ranges: newSearchRanges, direction: .previous) { return }
          _ = selectEdgeMatch(in: oldTextView, ranges: oldSearchRanges, direction: .previous)
        } else {
          if selectEdgeMatch(in: newTextView, ranges: newSearchRanges, direction: .previous) { return }
          _ = selectEdgeMatch(in: oldTextView, ranges: oldSearchRanges, direction: .previous)
        }
      }
    }

    private func selectMatch(
      in textView: NSTextView?,
      ranges: [NSRange],
      direction: DiffSearch.NavigationDirection,
      allowsWrap: Bool
    ) -> Bool {
      guard let textView,
            let range = DiffSearch.navigationRange(
              in: ranges,
              selectedRange: textView.selectedRange(),
              direction: direction,
              allowsWrap: allowsWrap
            ) else { return false }
      select(range, in: textView)
      return true
    }

    private func selectEdgeMatch(
      in textView: NSTextView?,
      ranges: [NSRange],
      direction: DiffSearch.NavigationDirection
    ) -> Bool {
      guard let textView else { return false }
      let selection: NSRange
      switch direction {
      case .next:
        selection = NSRange(location: 0, length: 0)
      case .previous:
        selection = NSRange(location: (textView.string as NSString).length, length: 0)
      }
      guard let range = DiffSearch.navigationRange(
        in: ranges,
        selectedRange: selection,
        direction: direction,
        allowsWrap: false
      ) else { return false }
      select(range, in: textView)
      return true
    }

    private func select(_ range: NSRange, in textView: NSTextView) {
      textView.setSelectedRange(range)
      textView.scrollRangeToVisible(range)
      textView.window?.makeFirstResponder(textView)
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
    textView.layoutManager?.allowsNonContiguousLayout = true
    textView.layoutManager?.backgroundLayoutEnabled = true
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
    numberWidth: Int,
    searchText: String
  ) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let baseFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    paragraph.lineSpacing = 1

    for index in lines.indices {
      let line = lines[index].text
      let counterpartLine = counterpart.indices.contains(index) ? counterpart[index].text : ""
      let renderedLine = SplitDiffRenderedSearch.renderLine(lines[index], numberWidth: numberWidth, counterpart: counterpartLine)
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
        attributes[.foregroundColor] = NSColor.tertiaryLabelColor
        attributes[.backgroundColor] = placeholderColor(for: counterpartLine)
      }

      let lineString = NSMutableAttributedString(string: renderedLine.text + "\n", attributes: attributes)
      let gutterRange = NSRange(location: 0, length: renderedLine.contentOffset)
      lineString.addAttributes([
        .foregroundColor: NSColor.tertiaryLabelColor,
        .backgroundColor: NSColor.textBackgroundColor.withAlphaComponent(0.35)
      ], range: gutterRange)

      if renderedLine.isPlaceholder {
        let placeholderRange = NSRange(
          location: renderedLine.contentOffset,
          length: min(DiffRenderPolicy.splitPlaceholderText.count, max(lineString.length - renderedLine.contentOffset, 0))
        )
        if placeholderRange.length > 0 {
          lineString.addAttributes([
            .foregroundColor: NSColor.tertiaryLabelColor,
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
          ], range: placeholderRange)
        }
      } else {
        let inlineRanges = inlineRanges(
          for: line,
          counterpart: counterpartLine,
          side: side,
          contentOffset: renderedLine.contentOffset,
          diffLineCount: lines.count
        )
        let highlightColor = side == .new
          ? NSColor.systemGreen.withAlphaComponent(0.24)
          : NSColor.systemRed.withAlphaComponent(0.24)
        for inlineRange in inlineRanges {
          lineString.addAttribute(.backgroundColor, value: highlightColor, range: inlineRange)
        }
      }
      if !renderedLine.isPlaceholder {
        applySearchHighlights(
          to: lineString,
          line: lines[index].displayText,
          contentOffset: renderedLine.contentOffset,
          searchText: searchText,
          lineCount: lines.count
        )
      }
      result.append(lineString)
    }
    return result
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

  private static func inlineRanges(
    for line: String,
    counterpart: String,
    side: SplitSide,
    contentOffset: Int,
    diffLineCount: Int
  ) -> [NSRange] {
    switch side {
    case .old:
      guard line.hasPrefix("-"), counterpart.hasPrefix("+") else { return [] }
      let oldLine = String(line.dropFirst())
      let newLine = String(counterpart.dropFirst())
      guard DiffRenderPolicy.allowsInlineHighlight(oldLine: oldLine, newLine: newLine, diffLineCount: diffLineCount) else { return [] }
      return DiffInlineHighlighter.changedRanges(old: oldLine, new: newLine).oldRanges.map {
        nsRange(for: $0, in: oldLine, markerOffset: contentOffset)
      }
    case .new:
      guard line.hasPrefix("+"), counterpart.hasPrefix("-") else { return [] }
      let oldLine = String(counterpart.dropFirst())
      let newLine = String(line.dropFirst())
      guard DiffRenderPolicy.allowsInlineHighlight(oldLine: oldLine, newLine: newLine, diffLineCount: diffLineCount) else { return [] }
      return DiffInlineHighlighter.changedRanges(old: oldLine, new: newLine).newRanges.map {
        nsRange(for: $0, in: newLine, markerOffset: contentOffset)
      }
    }
  }

  private static func nsRange(for range: Range<String.Index>, in line: String, markerOffset: Int) -> NSRange {
    let lower = line.distance(from: line.startIndex, to: range.lowerBound) + markerOffset
    let length = line.distance(from: range.lowerBound, to: range.upperBound)
    return NSRange(location: lower, length: length)
  }

  private static func applySearchHighlights(
    to lineString: NSMutableAttributedString,
    line: String,
    contentOffset: Int,
    searchText: String,
    lineCount: Int
  ) {
    guard lineCount <= DiffRenderPolicy.maxSearchHighlightLineCount else { return }
    let ranges = DiffSearch.ranges(in: line, query: searchText)
    guard !ranges.isEmpty else { return }

    let highlightColor = NSColor.systemYellow.withAlphaComponent(0.38)
    for range in ranges {
      let offsetRange = NSRange(location: range.location + contentOffset, length: range.length)
      guard NSMaxRange(offsetRange) <= lineString.length else { continue }
      lineString.addAttributes([
        .backgroundColor: highlightColor,
        .underlineStyle: NSUnderlineStyle.single.rawValue
      ], range: offsetRange)
    }
  }
}
