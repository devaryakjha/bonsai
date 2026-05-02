enum HistoryGraphColumn {
  static let minimumCharacters = 5
  static let pointsPerCharacter = 8.4

  static func characterWidth(for commits: [GitCommit]) -> Int {
    max(
      minimumCharacters,
      commits
        .map { $0.graph.isEmpty ? 1 : $0.graph.count }
        .max() ?? minimumCharacters
    )
  }

  static func pointWidth(for commits: [GitCommit]) -> Double {
    Double(characterWidth(for: commits)) * pointsPerCharacter
  }
}
