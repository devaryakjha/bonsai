import AppKit
import Foundation

enum FileOpenLauncher {
  static func targetURL(repository: GitRepository, path: String) -> URL {
    RepositoryFileLocator.fileURL(repository: repository, path: path)
  }

  static func openFile(repository: GitRepository, path: String) -> Bool {
    NSWorkspace.shared.open(targetURL(repository: repository, path: path))
  }

  static func applicationURL(for editor: ExternalEditor) -> URL? {
    editor.bundleIdentifiers.lazy.compactMap {
      NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0)
    }.first
  }

  static func openFile(repository: GitRepository, path: String, in editor: ExternalEditor) -> Bool {
    guard let applicationURL = applicationURL(for: editor) else { return false }
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    NSWorkspace.shared.open(
      [targetURL(repository: repository, path: path)],
      withApplicationAt: applicationURL,
      configuration: configuration
    )
    return true
  }
}

enum ExternalEditor: String, CaseIterable, Identifiable {
  case xcode
  case visualStudioCode
  case zed
  case sublimeText
  case bbedit
  case qtCreator

  var id: String { rawValue }

  var title: String {
    switch self {
    case .xcode:
      return "Xcode"
    case .visualStudioCode:
      return "Visual Studio Code"
    case .zed:
      return "Zed"
    case .sublimeText:
      return "Sublime Text"
    case .bbedit:
      return "BBEdit"
    case .qtCreator:
      return "Qt Creator"
    }
  }

  var commandTitle: String {
    "Open in \(title)"
  }

  var bundleIdentifiers: [String] {
    switch self {
    case .xcode:
      return ["com.apple.dt.Xcode"]
    case .visualStudioCode:
      return ["com.microsoft.VSCode", "com.microsoft.VSCodeInsiders"]
    case .zed:
      return ["dev.zed.Zed", "dev.zed.Zed-Preview"]
    case .sublimeText:
      return ["com.sublimetext.4", "com.sublimetext.3"]
    case .bbedit:
      return ["com.barebones.bbedit"]
    case .qtCreator:
      return ["org.qt-project.qtcreator"]
    }
  }
}
