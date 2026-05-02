enum GitHubNotificationSummary {
  static let maxItems = 8
  static let maxLineLength = 120

  static func output(for notifications: [GitHubNotification]) -> String {
    let lines = notifications.prefix(maxItems).map { notification in
      truncated("\(notification.repository.fullName): \(notification.subject.title)")
    }
    return lines.isEmpty ? "No unread notifications." : lines.joined(separator: "\n")
  }

  private static func truncated(_ line: String) -> String {
    guard line.count > maxLineLength else { return line }
    return "\(line.prefix(maxLineLength - 3))..."
  }
}
