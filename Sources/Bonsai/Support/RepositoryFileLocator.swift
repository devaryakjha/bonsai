import Foundation

enum RepositoryFileLocator {
  static func repositoryURL(_ repository: GitRepository) -> URL {
    URL(filePath: repository.path)
  }

  static func fileURL(repository: GitRepository, path: String) -> URL {
    repositoryURL(repository).appending(path: path)
  }

  static func filePath(repository: GitRepository, path: String) -> String {
    fileURL(repository: repository, path: path).path(percentEncoded: false)
  }
}
