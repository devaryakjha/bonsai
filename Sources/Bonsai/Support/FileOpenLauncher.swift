import AppKit
import Foundation

enum FileOpenLauncher {
  static func targetURL(repository: GitRepository, path: String) -> URL {
    RepositoryFileLocator.fileURL(repository: repository, path: path)
  }

  static func openFile(repository: GitRepository, path: String) -> Bool {
    NSWorkspace.shared.open(targetURL(repository: repository, path: path))
  }
}
