import SwiftUI

enum InterfaceSpacing {
  static let xSmall: CGFloat = 4
  static let small: CGFloat = 6
  static let medium: CGFloat = 8
  static let large: CGFloat = 10
  static let sidebarIconText: CGFloat = 10
  static let panelHorizontal: CGFloat = 12
  static let panelVertical: CGFloat = 8
  static let headerHorizontal: CGFloat = 14
  static let headerVertical: CGFloat = 10
}

enum InterfaceSize {
  static let sidebarIcon: CGFloat = 18
  static let sidebarIconColumn: CGFloat = 24
  static let compactIconButton: CGFloat = 26
  static let smallIconButton: CGFloat = 24
  static let headerControlHeight: CGFloat = 30
  static let headerIconButtonWidth: CGFloat = 34
  static let headerMenuButtonWidth: CGFloat = 52
  static let statusBadgeWidth: CGFloat = 24
  static let statusBadgeHeight: CGFloat = 18
  static let pillCornerRadius: CGFloat = 6
}

extension Font {
  static let bonsaiMetadata = Font.caption
  static let bonsaiTinyMetadata = Font.caption2
  static let bonsaiMonospacedMetadata = Font.caption.monospaced()
  static let bonsaiSheetTitle = Font.title3.weight(.semibold)
}

extension View {
  func bonsaiSidebarIconFrame() -> some View {
    font(.body)
      .imageScale(.medium)
      .frame(width: InterfaceSize.sidebarIconColumn, alignment: .center)
  }

  func bonsaiCompactIconButton() -> some View {
    font(.body)
      .buttonStyle(.borderless)
      .controlSize(.small)
      .frame(width: InterfaceSize.compactIconButton, height: InterfaceSize.compactIconButton)
      .contentShape(Rectangle())
  }

  func bonsaiSmallIconButton() -> some View {
    font(.body)
      .buttonStyle(.borderless)
      .controlSize(.small)
      .frame(width: InterfaceSize.smallIconButton, height: InterfaceSize.smallIconButton)
      .contentShape(Rectangle())
  }

  func bonsaiCompactMenuButton(width: CGFloat = InterfaceSize.compactIconButton) -> some View {
    font(.body)
      .menuStyle(.borderlessButton)
      .controlSize(.small)
      .frame(width: width, height: InterfaceSize.compactIconButton)
      .contentShape(Rectangle())
  }

  func bonsaiHeaderIconButton(width: CGFloat = InterfaceSize.headerIconButtonWidth) -> some View {
    font(.body)
      .buttonStyle(.bordered)
      .controlSize(.regular)
      .frame(width: width, height: InterfaceSize.headerControlHeight)
      .contentShape(Rectangle())
  }

  func bonsaiHeaderMenuButton(width: CGFloat = InterfaceSize.headerMenuButtonWidth) -> some View {
    font(.body)
      .menuStyle(.borderedButton)
      .controlSize(.regular)
      .frame(width: width, height: InterfaceSize.headerControlHeight)
      .contentShape(Rectangle())
  }

  func bonsaiHeaderPadding() -> some View {
    padding(.horizontal, InterfaceSpacing.headerHorizontal)
      .padding(.vertical, InterfaceSpacing.headerVertical)
  }

  func bonsaiPanelHeaderPadding() -> some View {
    padding(.horizontal, InterfaceSpacing.panelHorizontal)
      .padding(.vertical, InterfaceSpacing.panelVertical)
  }

  func metadataPillStyle<S: ShapeStyle>(foregroundStyle: S = .secondary, maxWidth: CGFloat? = nil) -> some View {
    font(.bonsaiTinyMetadata)
      .foregroundStyle(foregroundStyle)
      .lineLimit(1)
      .truncationMode(.middle)
      .frame(maxWidth: maxWidth)
      .padding(.horizontal, InterfaceSpacing.small)
      .padding(.vertical, 2)
      .background(.quaternary, in: Capsule())
  }
}

struct MetadataPill: View {
  var text: String
  var foregroundStyle: AnyShapeStyle
  var maxWidth: CGFloat?

  init<S: ShapeStyle>(_ text: String, foregroundStyle: S = .secondary, maxWidth: CGFloat? = nil) {
    self.text = text
    self.foregroundStyle = AnyShapeStyle(foregroundStyle)
    self.maxWidth = maxWidth
  }

  var body: some View {
    Text(text)
      .font(.bonsaiTinyMetadata)
      .foregroundStyle(foregroundStyle)
      .lineLimit(1)
      .truncationMode(.middle)
      .frame(maxWidth: maxWidth)
      .padding(.horizontal, InterfaceSpacing.small)
      .padding(.vertical, 2)
      .background(.quaternary, in: Capsule())
  }
}
