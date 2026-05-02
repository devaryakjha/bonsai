import SwiftUI

struct ChangeStatusBadge: View {
  var code: String
  var title: String

  init(changedFile: GitChangedFile) {
    code = changedFile.statusCode
    title = changedFile.statusTitle
  }

  init(statusEntry: GitStatusEntry) {
    code = statusEntry.statusCode
    title = statusEntry.statusTitle
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
    switch code {
    case "A":
      return (.green, .green.opacity(0.16))
    case "D":
      return (.red, .red.opacity(0.16))
    case "R":
      return (.purple, .purple.opacity(0.16))
    case "C":
      return (.blue, .blue.opacity(0.14))
    case "U":
      return (.orange, .orange.opacity(0.18))
    case "?":
      return (.secondary, .secondary.opacity(0.12))
    case "T", "M":
      return (.yellow, .yellow.opacity(0.16))
    default:
      return (.secondary, .secondary.opacity(0.10))
    }
  }
}
