import Foundation

enum ProjectRepositoryScanner {
  static let sourceDirectoriesDefaultsKey = "bonsai.sourceDirectories"

  static var defaultProjectsDirectory: URL {
    URL(filePath: NSHomeDirectory()).appending(path: "projects", directoryHint: .isDirectory)
  }

  static var defaultSourceDirectoryText: String {
    defaultProjectsDirectory.path(percentEncoded: false)
  }

  static func configuredSourceDirectories(rawValue: String? = nil) -> [URL] {
    let value = rawValue ?? UserDefaults.standard.string(forKey: sourceDirectoriesDefaultsKey) ?? defaultSourceDirectoryText
    let candidates = value
      .split(whereSeparator: \.isNewline)
      .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    let paths = candidates.isEmpty ? [defaultSourceDirectoryText] : candidates
    var seen: Set<String> = []
    return paths.compactMap { path in
      let url = expandedURL(path)
      let key = url.resolvingSymlinksInPath().standardizedFileURL.path(percentEncoded: false)
      guard seen.insert(key).inserted else { return nil }
      return url
    }
  }

  static func scanDefaultProjectsDirectory() -> [GitRepository] {
    scanRepositories(under: defaultProjectsDirectory, maxDepth: 2)
  }

  static func scanDefaultWorkspaceGroups() -> [WorkspaceGroup] {
    scanConfiguredWorkspaceGroups()
  }

  static func scanConfiguredRepositories(maxDepth: Int = 2) -> [GitRepository] {
    let repositories = configuredSourceDirectories().flatMap { root in
      scanRepositories(under: root, maxDepth: maxDepth)
    }
    return uniqueRepositories(repositories)
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  static func scanConfiguredWorkspaceGroups(maxDepth: Int = 2) -> [WorkspaceGroup] {
    workspaceGroups(under: configuredSourceDirectories(), maxDepth: maxDepth)
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
        let groupURL = name == "Projects" ? root : root.appending(path: name)
        return WorkspaceGroup(
          name: name,
          path: groupURL.path(percentEncoded: false),
          repositories: repositories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        )
      }
      .sorted { lhs, rhs in
        if lhs.name == "Projects" { return true }
        if rhs.name == "Projects" { return false }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
      }
  }

  static func workspaceGroups(under roots: [URL], maxDepth: Int) -> [WorkspaceGroup] {
    let uniqueRoots = uniqueURLs(roots)
    let multipleRoots = uniqueRoots.count > 1
    let groups = uniqueRoots.flatMap { root in
      workspaceGroups(under: root, maxDepth: maxDepth).map { group in
        guard multipleRoots else { return group }
        let sourceName = root.lastPathComponent.isEmpty ? root.path(percentEncoded: false) : root.lastPathComponent
        let rootPath = root.resolvingSymlinksInPath().standardizedFileURL.path(percentEncoded: false)
        let groupPath = URL(filePath: group.path, directoryHint: .isDirectory)
          .resolvingSymlinksInPath()
          .standardizedFileURL
          .path(percentEncoded: false)
        let name = groupPath == rootPath ? sourceName : "\(sourceName) / \(group.name)"
        return WorkspaceGroup(name: name, path: group.path, repositories: group.repositories)
      }
    }

    var seen: Set<String> = []
    return groups
      .filter { group in
        seen.insert(group.path).inserted
      }
      .sorted { lhs, rhs in
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
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

  private static func expandedURL(_ path: String) -> URL {
    let expandedPath: String
    if path == "~" {
      expandedPath = NSHomeDirectory()
    } else if path.hasPrefix("~/") {
      expandedPath = NSHomeDirectory() + String(path.dropFirst())
    } else {
      expandedPath = path
    }
    return URL(filePath: expandedPath)
  }

  private static func uniqueURLs(_ urls: [URL]) -> [URL] {
    var seen: Set<String> = []
    return urls.filter { url in
      let key = url.resolvingSymlinksInPath().standardizedFileURL.path(percentEncoded: false)
      return seen.insert(key).inserted
    }
  }

  private static func uniqueRepositories(_ repositories: [GitRepository]) -> [GitRepository] {
    var seen: Set<String> = []
    return repositories.filter { repository in
      let key = URL(filePath: repository.path, directoryHint: .isDirectory)
        .resolvingSymlinksInPath()
        .standardizedFileURL
        .path(percentEncoded: false)
      return seen.insert(key).inserted
    }
  }
}
