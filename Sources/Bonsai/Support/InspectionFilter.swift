enum InspectionFilter {
  static func fileHistory(
    _ entries: [GitFileHistoryEntry],
    matching query: String
  ) -> [GitFileHistoryEntry] {
    let terms = searchTerms(from: query)
    guard !terms.isEmpty else { return entries }

    return entries.filter { entry in
      matches(terms: terms, in: entry.inspectionSearchFields)
    }
  }

  static func blameLines(
    _ lines: [GitBlameLine],
    matching query: String
  ) -> [GitBlameLine] {
    let terms = searchTerms(from: query)
    guard !terms.isEmpty else { return lines }

    return lines.filter { line in
      matches(terms: terms, in: line.inspectionSearchFields)
    }
  }

  private static func searchTerms(from query: String) -> [String] {
    query
      .split(whereSeparator: \.isWhitespace)
      .map { $0.lowercased() }
  }

  private static func matches(terms: [String], in fields: [String]) -> Bool {
    let haystack = fields.joined(separator: "\n").lowercased()
    return terms.allSatisfy { haystack.contains($0) }
  }
}

private extension GitFileHistoryEntry {
  var inspectionSearchFields: [String] {
    [
      hash,
      shortHash,
      subject,
      authorName,
      authorEmail
    ] + changes.flatMap(\.inspectionSearchFields)
  }
}

private extension GitChangedFile {
  var inspectionSearchFields: [String] {
    [
      status,
      statusCode,
      statusTitle,
      path,
      oldPath ?? ""
    ]
  }
}

private extension GitBlameLine {
  var inspectionSearchFields: [String] {
    [
      commitHash,
      shortHash,
      author,
      authorMail ?? "",
      String(originalLine),
      String(finalLine),
      content
    ]
  }
}
