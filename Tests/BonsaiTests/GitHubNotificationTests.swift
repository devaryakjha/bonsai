import XCTest
@testable import Bonsai

final class GitHubNotificationTests: XCTestCase {
  func testDecodeNotificationThread() throws {
    let data = """
    [
      {
        "id": "1",
        "unread": true,
        "reason": "mention",
        "updated_at": "2026-05-02T00:00:00Z",
        "subject": {
          "title": "Review requested",
          "type": "PullRequest",
          "url": "https://api.github.com/repos/example/bonsai/pulls/1"
        },
        "repository": {
          "full_name": "example/bonsai"
        }
      }
    ]
    """.data(using: .utf8)!

    let notifications = try JSONDecoder().decode([GitHubNotification].self, from: data)

    XCTAssertEqual(notifications.count, 1)
    XCTAssertEqual(notifications[0].repository.fullName, "example/bonsai")
    XCTAssertEqual(notifications[0].subject.title, "Review requested")
    XCTAssertEqual(notifications[0].reason, "mention")
  }
}
