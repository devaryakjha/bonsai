import Foundation

enum GitParsers {
  static func parseStatus(_ output: String) -> [GitStatusEntry] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .compactMap { line -> GitStatusEntry? in
        guard line.count >= 4 else { return nil }
        let index = line[line.startIndex]
        let workTree = line[line.index(after: line.startIndex)]
        let pathStart = line.index(line.startIndex, offsetBy: 3)
        let rawPath = String(line[pathStart...])
        let renameParts = rawPath.components(separatedBy: " -> ")
        let path = renameParts.last ?? rawPath
        let originalPath = renameParts.count > 1 ? renameParts.first : nil
        let kind = changeKind(index: index, workTree: workTree)
        return GitStatusEntry(
          path: path,
          originalPath: originalPath,
          indexStatus: index,
          workTreeStatus: workTree,
          kind: kind
        )
      }
  }

  static func parseCommits(_ output: String) -> [GitCommit] {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let fallbackFormatter = ISO8601DateFormatter()
    fallbackFormatter.formatOptions = [.withInternetDateTime]

    return output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .compactMap { line -> GitCommit? in
        let parts = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 7 else { return nil }
        let decorations = parts[6]
          .split(separator: ",")
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty }
        return GitCommit(
          hash: parts[0],
          shortHash: parts[1],
          authorName: parts[2],
          authorEmail: parts[3],
          date: formatter.date(from: parts[4]) ?? fallbackFormatter.date(from: parts[4]),
          subject: parts[5],
          decorations: decorations
        )
      }
  }

  static func parseRefs(_ output: String) -> [GitRef] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .compactMap { line -> GitRef? in
        let parts = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 4 else { return nil }
        let refname = parts[0]
        let kind: GitRef.RefKind
        let shortName: String
        if refname.hasPrefix("refs/heads/") {
          kind = .localBranch
          shortName = String(refname.dropFirst("refs/heads/".count))
        } else if refname.hasPrefix("refs/remotes/") {
          kind = .remoteBranch
          shortName = String(refname.dropFirst("refs/remotes/".count))
        } else if refname.hasPrefix("refs/tags/") {
          kind = .tag
          shortName = String(refname.dropFirst("refs/tags/".count))
        } else {
          return nil
        }

        return GitRef(
          name: refname,
          shortName: shortName,
          objectName: parts[1],
          upstream: parts[2].isEmpty ? nil : parts[2],
          isHead: parts[3] == "*",
          kind: kind
        )
      }
  }

  static func parseRemotes(_ output: String) -> [GitRemote] {
    var remotes: [String: GitRemote] = [:]
    for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
      let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
      guard parts.count >= 3 else { continue }
      let name = parts[0]
      let url = parts[1]
      let mode = parts[2]
      var remote = remotes[name] ?? GitRemote(name: name, fetchURL: nil, pushURL: nil)
      if mode.contains("fetch") {
        remote.fetchURL = url
      } else if mode.contains("push") {
        remote.pushURL = url
      }
      remotes[name] = remote
    }
    return remotes.values.sorted { $0.name < $1.name }
  }

  static func parseStashes(_ output: String) -> [GitStash] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .map { line in
        let text = String(line)
        let pieces = text.components(separatedBy: ": ")
        let index = pieces.first ?? text
        let message = pieces.dropFirst().joined(separator: ": ")
        let branch = message.components(separatedBy: " WIP on ").last?.components(separatedBy: ":").first
        return GitStash(index: index, branch: branch, message: message.isEmpty ? text : message)
      }
  }

  static func parseSubmodules(_ output: String) -> [GitSubmodule] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .compactMap { line -> GitSubmodule? in
        let status = String(line.prefix(1))
        let rest = line.dropFirst().trimmingCharacters(in: .whitespaces)
        let parts = rest.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else { return nil }
        return GitSubmodule(path: parts[1], commit: parts[0], status: status)
      }
  }

  static func parseChangedFiles(_ output: String) -> [GitChangedFile] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .compactMap { line -> GitChangedFile? in
        let parts = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2 else { return nil }
        if parts[0].hasPrefix("R"), parts.count >= 3 {
          return GitChangedFile(status: parts[0], path: parts[2], oldPath: parts[1])
        }
        return GitChangedFile(status: parts[0], path: parts[1], oldPath: nil)
      }
  }

  private static func changeKind(index: Character, workTree: Character) -> GitStatusEntry.ChangeKind {
    let status = "\(index)\(workTree)"
    if ["DD", "AU", "UD", "UA", "DU", "AA", "UU"].contains(status) {
      return .conflicted
    }
    if index == "?" || workTree == "?" { return .untracked }
    if index == "R" || workTree == "R" { return .renamed }
    if index == "C" || workTree == "C" { return .copied }
    if index == "A" || workTree == "A" { return .added }
    if index == "D" || workTree == "D" { return .deleted }
    if index == "T" || workTree == "T" { return .typeChanged }
    if index == "M" || workTree == "M" { return .modified }
    return .unknown
  }
}
