import AppKit
import SwiftUI

struct ChangeStatusBadge: View {
  var code: String
  var title: String
  var role: GitChangeStatusRole

  init(changedFile: GitChangedFile) {
    code = changedFile.statusCode
    title = changedFile.statusTitle
    role = changedFile.statusRole
  }

  init(statusEntry: GitStatusEntry) {
    code = statusEntry.statusCode
    title = statusEntry.statusTitle
    role = statusEntry.statusRole
  }

  var body: some View {
    Text(code)
      .font(.bonsaiTinyMetadata.monospaced().weight(.semibold))
      .lineLimit(1)
      .minimumScaleFactor(0.85)
      .foregroundStyle(style.foreground)
      .frame(width: InterfaceSize.statusBadgeWidth, height: InterfaceSize.statusBadgeHeight)
      .background {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .fill(style.background)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .stroke(style.border, lineWidth: 0.5)
      }
      .help("\(title) (\(code))")
      .accessibilityLabel(title)
      .accessibilityHint("\(role.colorToken.conventionalName) Git change status")
  }

  private var style: (foreground: Color, background: Color, border: Color) {
    switch role.colorToken {
    case .green:
      return palette(.systemGreen)
    case .red:
      return palette(.systemRed)
    case .amber:
      return palette(foreground: .systemOrange, background: .systemYellow)
    case .purple:
      return palette(.systemPurple)
    case .blue:
      return palette(.systemBlue)
    case .orange:
      return palette(.systemOrange)
    case .neutral:
      return (.secondary, .secondary.opacity(0.14), .secondary.opacity(0.24))
    }
  }

  private func palette(_ color: NSColor) -> (foreground: Color, background: Color, border: Color) {
    palette(foreground: color, background: color)
  }

  private func palette(
    foreground foregroundColor: NSColor,
    background backgroundColor: NSColor
  ) -> (foreground: Color, background: Color, border: Color) {
    let foreground = Color(nsColor: foregroundColor)
    let background = Color(nsColor: backgroundColor)
    return (foreground, background.opacity(0.26), foreground.opacity(0.36))
  }
}
