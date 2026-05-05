import CoreGraphics

enum SplitDiffLayoutPolicy {
  static let minimumSideBySideWidth: CGFloat = 640
  static let minimumSideBySidePaneLength: CGFloat = 280
  static let minimumStackedPaneLength: CGFloat = 160

  static func usesSideBySide(width: CGFloat) -> Bool {
    width >= minimumSideBySideWidth
  }

  static func minimumPaneLength(isSideBySide: Bool) -> CGFloat {
    isSideBySide ? minimumSideBySidePaneLength : minimumStackedPaneLength
  }

  static func clampedDividerPosition(
    length: CGFloat,
    proposedPosition: CGFloat,
    isSideBySide: Bool
  ) -> CGFloat {
    guard length > 0 else { return proposedPosition }
    let minimumLength = minimumPaneLength(isSideBySide: isSideBySide)
    guard length >= minimumLength * 2 else {
      return length / 2
    }
    return min(max(proposedPosition, minimumLength), length - minimumLength)
  }

  static func dividerPositionNeedsRepair(
    length: CGFloat,
    position: CGFloat,
    isSideBySide: Bool
  ) -> Bool {
    abs(clampedDividerPosition(
      length: length,
      proposedPosition: position,
      isSideBySide: isSideBySide
    ) - position) > 0.5
  }
}
