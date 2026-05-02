import Foundation

enum RepositoryFileLocator {
  static func fileURL(repository: GitRepository, path: String) -> URL {
    URL(filePath: repository.path, directoryHint: .isDirectory)
      .appending(path: path)
  }
}
