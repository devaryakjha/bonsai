import CoreGraphics

enum SplitDiffLayoutPolicy {
  static let minimumSideBySideWidth: CGFloat = 640

  static func usesSideBySide(width: CGFloat) -> Bool {
    width >= minimumSideBySideWidth
  }
}
