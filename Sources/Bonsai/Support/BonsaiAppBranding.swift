import AppKit

enum BonsaiAppBranding {
  static let appName = "Bonsai"
  static let iconResourceName = "Bonsai"
  static let markResourceName = "bonsai-worktree-topology"

  static func iconImage(bundle: Bundle = .main) -> NSImage? {
    for candidate in iconResourceCandidates {
      if let url = bundle.url(forResource: candidate.name, withExtension: candidate.extension),
         let image = NSImage(contentsOf: url) {
        return image
      }
    }

    return NSImage(named: NSImage.applicationIconName)
  }

  static func aboutPanelOptions(icon: NSImage? = iconImage()) -> [NSApplication.AboutPanelOptionKey: Any] {
    var options: [NSApplication.AboutPanelOptionKey: Any] = [
      .applicationName: appName,
      .credits: credits
    ]

    if let icon {
      options[.applicationIcon] = icon
    }

    return options
  }

  @MainActor
  static func installApplicationIcon(bundle: Bundle = .main) {
    guard let icon = iconImage(bundle: bundle) else { return }
    NSApplication.shared.applicationIconImage = icon
  }

  @MainActor
  static func showAboutPanel() {
    NSApplication.shared.orderFrontStandardAboutPanel(options: aboutPanelOptions())
  }

  private static let iconResourceCandidates: [(name: String, extension: String)] = [
    (iconResourceName, "icns"),
    (markResourceName, "svg")
  ]

  private static var credits: NSAttributedString {
    NSAttributedString(
      string: "A native Git client for macOS.",
      attributes: [
        .foregroundColor: NSColor.secondaryLabelColor
      ]
    )
  }
}
