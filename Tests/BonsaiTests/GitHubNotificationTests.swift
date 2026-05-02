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

  func testGitHubRepositoryTargetParsesCommonRemoteURLs() {
    XCTAssertEqual(
      GitHubRepositoryTarget(remoteURL: "https://github.com/example/bonsai.git"),
      GitHubRepositoryTarget(owner: "example", name: "bonsai")
    )
    XCTAssertEqual(
      GitHubRepositoryTarget(remoteURL: "git@github.com:example/bonsai.git"),
      GitHubRepositoryTarget(owner: "example", name: "bonsai")
    )
    XCTAssertEqual(
      GitHubRepositoryTarget(remoteURL: "ssh://git@github.com/example/bonsai"),
      GitHubRepositoryTarget(owner: "example", name: "bonsai")
    )
    XCTAssertNil(GitHubRepositoryTarget(remoteURL: "git@gitlab.com:example/bonsai.git"))
  }

  func testRemoteExposesFirstGitHubRepositoryTarget() {
    let remote = GitRemote(
      name: "origin",
      fetchURL: "git@gitlab.com:example/other.git",
      pushURL: "git@github.com:example/bonsai.git"
    )

    XCTAssertEqual(remote.githubRepositoryTarget, GitHubRepositoryTarget(owner: "example", name: "bonsai"))
  }

  @MainActor
  func testDeleteRepositoryRequestPrefersOriginGitHubRemote() {
    let store = RepositoryStore()
    store.selectedRepository = GitRepository(path: "/tmp/local-name")
    store.snapshot.remotes = [
      GitRemote(
        name: "backup",
        fetchURL: "git@github.com:backup/remote.git",
        pushURL: nil
      ),
      GitRemote(
        name: "origin",
        fetchURL: "https://github.com/example/bonsai.git",
        pushURL: nil
      )
    ]

    store.presentDeleteGitHubRepository()

    XCTAssertEqual(store.gitHubRepositoryRequest?.operation, .delete)
    XCTAssertEqual(store.gitHubRepositoryRequest?.owner, "example")
    XCTAssertEqual(store.gitHubRepositoryRequest?.name, "bonsai")
  }

  @MainActor
  func testDeleteRepositoryRequestFallsBackWhenOriginIsNotGitHub() {
    let store = RepositoryStore()
    store.selectedRepository = GitRepository(path: "/tmp/local-name")
    store.snapshot.remotes = [
      GitRemote(
        name: "origin",
        fetchURL: "git@gitlab.com:example/local-name.git",
        pushURL: nil
      ),
      GitRemote(
        name: "upstream",
        fetchURL: "git@github.com:example/upstream.git",
        pushURL: nil
      )
    ]

    store.presentDeleteGitHubRepository()

    XCTAssertEqual(store.gitHubRepositoryRequest?.owner, "example")
    XCTAssertEqual(store.gitHubRepositoryRequest?.name, "upstream")

    store.snapshot.remotes = [
      GitRemote(
        name: "origin",
        fetchURL: "git@gitlab.com:example/local-name.git",
        pushURL: nil
      )
    ]

    store.presentDeleteGitHubRepository()

    XCTAssertEqual(store.gitHubRepositoryRequest?.owner, "")
    XCTAssertEqual(store.gitHubRepositoryRequest?.name, "local-name")
  }

  func testGitHubClientErrorCopyIsProviderLevel() {
    XCTAssertEqual(GitHubClientError.invalidURL.localizedDescription, "GitHub request URL is invalid.")
    XCTAssertEqual(GitHubClientError.invalidResponse.localizedDescription, "GitHub returned an invalid response.")
    XCTAssertEqual(GitHubClientError.httpStatus(404).localizedDescription, "GitHub request failed with HTTP 404.")
  }
}
