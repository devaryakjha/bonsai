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

  func testDecodeGitHubRepository() throws {
    let data = """
    {
      "id": 42,
      "name": "bonsai",
      "full_name": "example/bonsai",
      "html_url": "https://github.com/example/bonsai",
      "clone_url": "https://github.com/example/bonsai.git",
      "ssh_url": "git@github.com:example/bonsai.git",
      "private": true
    }
    """.data(using: .utf8)!

    let repository = try JSONDecoder().decode(GitHubRepository.self, from: data)

    XCTAssertEqual(repository.id, 42)
    XCTAssertEqual(repository.fullName, "example/bonsai")
    XCTAssertEqual(repository.cloneURL, "https://github.com/example/bonsai.git")
    XCTAssertTrue(repository.isPrivate)
  }
}
