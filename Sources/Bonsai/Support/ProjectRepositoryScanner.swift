import Foundation

enum ProjectRepositoryScanner {
  static func scanDefaultProjectsDirectory() -> [GitRepository] {
    let projectsURL = URL(filePath: NSHomeDirectory()).appending(path: "projects", directoryHint: .isDirectory)
    return scanRepositories(under: projectsURL, maxDepth: 2)
  }

  static func scanDefaultWorkspaceGroups() -> [WorkspaceGroup] {
    let projectsURL = URL(filePath: NSHomeDirectory()).appending(path: "projects", directoryHint: .isDirectory)
    return workspaceGroups(under: projectsURL, maxDepth: 2)
  }

  static func scanRepositories(under root: URL, maxDepth: Int) -> [GitRepository] {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: root.path(percentEncoded: false)) else {
      return []
    }

    var repositories: [GitRepository] = []
    scanDirectory(root, depth: 0, maxDepth: maxDepth, fileManager: fileManager, repositories: &repositories)
    return repositories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  static func workspaceGroups(under root: URL, maxDepth: Int) -> [WorkspaceGroup] {
    let repositories = scanRepositories(under: root, maxDepth: maxDepth)
    var grouped: [String: [GitRepository]] = [:]
    let rootComponents = root.resolvingSymlinksInPath().standardizedFileURL.pathComponents

    for repository in repositories {
      let repositoryURL = URL(filePath: repository.path, directoryHint: .isDirectory)
        .resolvingSymlinksInPath()
        .standardizedFileURL
      let components = Array(repositoryURL.pathComponents.dropFirst(rootComponents.count))
      let groupName = components.count > 1 ? components[0] : "Projects"
      grouped[groupName, default: []].append(repository)
    }

    return grouped
      .map { name, repositories in
        WorkspaceGroup(
          name: name,
          repositories: repositories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        )
      }
      .sorted { lhs, rhs in
        if lhs.name == "Projects" { return true }
        if rhs.name == "Projects" { return false }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
      }
  }

  private static func scanDirectory(
    _ directory: URL,
    depth: Int,
    maxDepth: Int,
    fileManager: FileManager,
    repositories: inout [GitRepository]
  ) {
    guard depth <= maxDepth else { return }

    let gitPath = directory.appending(path: ".git").path(percentEncoded: false)
    if fileManager.fileExists(atPath: gitPath) {
      repositories.append(GitRepository(path: directory.path(percentEncoded: false)))
      return
    }

    guard let contents = try? fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
      options: [.skipsPackageDescendants]
    ) else {
      return
    }

    for child in contents {
      guard let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey]),
            values.isDirectory == true,
            values.isHidden != true else {
        continue
      }
      scanDirectory(child, depth: depth + 1, maxDepth: maxDepth, fileManager: fileManager, repositories: &repositories)
    }
  }
}
