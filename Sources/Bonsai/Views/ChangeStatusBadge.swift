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
      .font(.caption2.monospaced().weight(.semibold))
      .foregroundStyle(style.foreground)
      .frame(width: 22, height: 18)
      .background(style.background, in: RoundedRectangle(cornerRadius: 4))
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .stroke(style.foreground.opacity(0.30), lineWidth: 0.5)
      }
      .help(title)
      .accessibilityLabel(title)
  }

  private var style: (foreground: Color, background: Color) {
    switch role {
    case .added:
      return palette(.systemGreen)
    case .deleted:
      return palette(.systemRed)
    case .modified:
      return palette(.systemYellow)
    case .renamed:
      return palette(.systemPurple)
    case .copied:
      return palette(.systemBlue)
    case .conflicted:
      return palette(.systemOrange)
    case .untracked, .unknown:
      return (.secondary, .secondary.opacity(0.12))
    }
  }

  private func palette(_ color: NSColor) -> (foreground: Color, background: Color) {
    let accent = Color(nsColor: color)
    return (accent, accent.opacity(0.22))
  }
}
