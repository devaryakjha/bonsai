import Foundation

enum GitParsers {
  static func parseStatus(_ output: String) -> [GitStatusEntry] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .flatMap { line -> [GitStatusEntry] in
        guard line.count >= 4 else { return [] }
        let index = line[line.startIndex]
        let workTree = line[line.index(after: line.startIndex)]
        let pathStart = line.index(line.startIndex, offsetBy: 3)
        let rawPath = String(line[pathStart...])
        let renameParts = rawPath.components(separatedBy: " -> ")
        let path = renameParts.last ?? rawPath
        let originalPath = renameParts.count > 1 ? renameParts.first : nil

        if shouldSplitStatus(index: index, workTree: workTree) {
          return [
            GitStatusEntry(
              path: path,
              originalPath: originalPath,
              indexStatus: index,
              workTreeStatus: " ",
              kind: changeKind(index: index, workTree: " ")
            ),
            GitStatusEntry(
              path: path,
              originalPath: nil,
              indexStatus: " ",
              workTreeStatus: workTree,
              kind: changeKind(index: " ", workTree: workTree)
            )
          ]
        }

        return [GitStatusEntry(
          path: path,
          originalPath: originalPath,
          indexStatus: index,
          workTreeStatus: workTree,
          kind: changeKind(index: index, workTree: workTree)
        )]
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

  static func parseWorktrees(_ output: String) -> [GitWorktree] {
    var worktrees: [GitWorktree] = []
    var path: String?
    var head: String?
    var branch: String?
    var isDetached = false
    var isBare = false
    var isPrunable = false

    func flush() {
      guard let path else { return }
      worktrees.append(GitWorktree(
        path: path,
        head: head,
        branch: branch,
        isDetached: isDetached,
        isBare: isBare,
        isPrunable: isPrunable
      ))
    }

    for line in output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
      if line.isEmpty {
        flush()
        path = nil
        head = nil
        branch = nil
        isDetached = false
        isBare = false
        isPrunable = false
      } else if line.hasPrefix("worktree ") {
        path = String(line.dropFirst("worktree ".count))
      } else if line.hasPrefix("HEAD ") {
        head = String(line.dropFirst("HEAD ".count))
      } else if line.hasPrefix("branch ") {
        branch = String(line.dropFirst("branch ".count))
      } else if line == "detached" {
        isDetached = true
      } else if line == "bare" {
        isBare = true
      } else if line.hasPrefix("prunable") {
        isPrunable = true
      }
    }
    flush()

    return worktrees
  }

  static func parseLFSFiles(_ output: String) -> [GitLFSFile] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .compactMap { line -> GitLFSFile? in
        let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)
        guard parts.count >= 3 else { return nil }
        return GitLFSFile(oid: parts[0], path: parts[2])
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

  static func parseTreeEntries(_ output: String, basePath: String = "") -> [GitTreeEntry] {
    output
      .split(separator: "\0", omittingEmptySubsequences: true)
      .compactMap { record -> GitTreeEntry? in
        let parts = record.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let metadata = parts[0].split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard metadata.count >= 3 else { return nil }

        let name = String(parts[1])
        let path = basePath.isEmpty ? name : "\(basePath)/\(name)"
        return GitTreeEntry(
          mode: metadata[0],
          kind: GitTreeEntry.EntryKind(rawValue: metadata[1]) ?? .unknown,
          object: metadata[2],
          path: path,
          name: name
        )
      }
  }

  static func parseDiffHunks(_ output: String) -> [DiffHunk] {
    let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var fileHeader: [String] = []
    var currentHeader: String?
    var currentLines: [String] = []
    var hunks: [DiffHunk] = []

    func flush() {
      guard let currentHeader else { return }
      hunks.append(DiffHunk(
        id: hunks.count,
        fileHeader: fileHeader,
        header: currentHeader,
        lines: currentLines
      ))
      currentLines = []
    }

    for line in lines {
      if line.hasPrefix("diff --git") {
        flush()
        fileHeader = [line]
        currentHeader = nil
        currentLines = []
      } else if line.hasPrefix("@@") {
        flush()
        currentHeader = line
      } else if currentHeader == nil {
        if !line.isEmpty {
          fileHeader.append(line)
        }
      } else {
        currentLines.append(line)
      }
    }
    flush()

    return hunks
  }

  static func parseSplitDiff(_ output: String) -> SplitDiff {
    var oldLines: [String] = []
    var newLines: [String] = []

    for line in output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
      if line.hasPrefix("diff --git") || line.hasPrefix("index ") || line.hasPrefix("---") || line.hasPrefix("+++") {
        continue
      }
      if line.hasPrefix("@@") {
        oldLines.append(line)
        newLines.append(line)
      } else if line.hasPrefix("-") {
        oldLines.append(line)
        newLines.append("")
      } else if line.hasPrefix("+") {
        oldLines.append("")
        newLines.append(line)
      } else if line.hasPrefix("\\ No newline") {
        continue
      } else {
        oldLines.append(line)
        newLines.append(line)
      }
    }

    return SplitDiff(oldText: oldLines.joined(separator: "\n"), newText: newLines.joined(separator: "\n"))
  }

  static func parseDiffLineChanges(_ hunk: DiffHunk) -> [DiffLineChange] {
    guard let ranges = parseHunkRanges(hunk.header) else { return [] }
    var changes: [DiffLineChange] = []
    var oldLine = ranges.oldStart
    var newLine = ranges.newStart
    var index = 0

    while index < hunk.lines.count {
      let line = hunk.lines[index]

      if line.hasPrefix(" ") {
        oldLine += 1
        newLine += 1
        index += 1
        continue
      }

      if line.hasPrefix("-") {
        let oldStart = oldLine
        let newStart = newLine
        var patchLines: [String] = []
        var oldCount = 0
        var newCount = 0

        while index < hunk.lines.count, hunk.lines[index].hasPrefix("-") {
          patchLines.append(hunk.lines[index])
          oldLine += 1
          oldCount += 1
          index += 1
        }

        while index < hunk.lines.count, hunk.lines[index].hasPrefix("+") {
          patchLines.append(hunk.lines[index])
          newLine += 1
          newCount += 1
          index += 1
        }

        let kind: DiffLineChange.Kind = newCount > 0 ? .replacement : .deletion
        changes.append(DiffLineChange(
          id: "\(hunk.id)-\(changes.count)",
          hunkID: hunk.id,
          kind: kind,
          oldStart: oldStart,
          oldCount: oldCount,
          newStart: kind == .deletion ? max(newStart - 1, 0) : newStart,
          newCount: newCount,
          lines: patchLines,
          fileHeader: hunk.fileHeader
        ))
        continue
      }

      if line.hasPrefix("+") {
        let oldStart = max(oldLine - 1, 0)
        let newStart = newLine
        let change = DiffLineChange(
          id: "\(hunk.id)-\(changes.count)",
          hunkID: hunk.id,
          kind: .addition,
          oldStart: oldStart,
          oldCount: 0,
          newStart: newStart,
          newCount: 1,
          lines: [line],
          fileHeader: hunk.fileHeader
        )
        changes.append(change)
        newLine += 1
        index += 1
        continue
      }

      index += 1
    }

    return changes
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

  private static func shouldSplitStatus(index: Character, workTree: Character) -> Bool {
    guard index != " ", workTree != " " else { return false }
    guard index != "?", workTree != "?", index != "!", workTree != "!" else { return false }
    return !["DD", "AU", "UD", "UA", "DU", "AA", "UU"].contains("\(index)\(workTree)")
  }

  private static func parseHunkRanges(_ header: String) -> (oldStart: Int, newStart: Int)? {
    let pieces = header.split(separator: " ")
    guard pieces.count >= 3,
          pieces[1].hasPrefix("-"),
          pieces[2].hasPrefix("+") else {
      return nil
    }

    func start(_ token: Substring) -> Int? {
      let value = token.dropFirst().split(separator: ",").first.map(String.init) ?? ""
      return Int(value)
    }

    guard let oldStart = start(pieces[1]),
          let newStart = start(pieces[2]) else {
      return nil
    }
    return (oldStart, newStart)
  }
}
