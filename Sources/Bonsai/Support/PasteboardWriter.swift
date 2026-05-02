import AppKit

enum PasteboardWriter {
  static func copy(_ value: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
  }
}
