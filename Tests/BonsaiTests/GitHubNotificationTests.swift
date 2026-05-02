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

  func testGitHubNotificationSummaryIsEmptyWhenNoUnreadThreadsExist() {
    XCTAssertEqual(GitHubNotificationSummary.output(for: []), "No unread notifications.")
  }

  func testGitHubNotificationSummaryIsCappedAndTruncated() {
    let notifications = (1...10).map { index in
      GitHubNotification(
        id: "\(index)",
        unread: true,
        reason: "mention",
        updatedAt: "2026-05-02T00:00:00Z",
        subject: GitHubNotification.Subject(
          title: index == 1 ? String(repeating: "A", count: 160) : "Thread \(index)",
          type: "PullRequest",
          url: nil
        ),
        repository: GitHubNotification.Repository(fullName: "example/bonsai")
      )
    }

    let lines = GitHubNotificationSummary.output(for: notifications).split(separator: "\n").map(String.init)

    XCTAssertEqual(lines.count, 8)
    XCTAssertTrue(lines[0].hasSuffix("..."))
    XCTAssertLessThanOrEqual(lines[0].count, GitHubNotificationSummary.maxLineLength)
    XCTAssertEqual(lines[7], "example/bonsai: Thread 8")
  }

  @MainActor
  func testMissingGitHubTokenSurfacesNotificationCommandResult() async {
    let previousToken = UserDefaults.standard.string(forKey: "bonsai.githubToken")
    UserDefaults.standard.removeObject(forKey: "bonsai.githubToken")
    defer {
      if let previousToken {
        UserDefaults.standard.set(previousToken, forKey: "bonsai.githubToken")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.githubToken")
      }
    }

    let store = RepositoryStore()

    await store.fetchGitHubNotifications()

    XCTAssertEqual(store.commandResult?.title, "GitHub notifications")
    XCTAssertEqual(store.commandResult?.isError, true)
    XCTAssertEqual(store.commandResult?.output, "Add a GitHub personal access token in Settings first.")
    XCTAssertEqual(store.errorMessage, "Add a GitHub personal access token in Settings first.")
  }

  @MainActor
  func testMissingGitHubTokenSurfacesMarkReadCommandResult() async {
    let previousToken = UserDefaults.standard.string(forKey: "bonsai.githubToken")
    UserDefaults.standard.removeObject(forKey: "bonsai.githubToken")
    defer {
      if let previousToken {
        UserDefaults.standard.set(previousToken, forKey: "bonsai.githubToken")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.githubToken")
      }
    }

    let store = RepositoryStore()

    await store.markGitHubNotificationsRead()

    XCTAssertEqual(store.commandResult?.title, "GitHub notifications")
    XCTAssertEqual(store.commandResult?.isError, true)
    XCTAssertEqual(store.commandResult?.output, "Add a GitHub personal access token in Settings first.")
  }

  @MainActor
  func testMissingGitHubTokenSurfacesRepositoryCommandResultWithoutDismissingRequest() async {
    let previousToken = UserDefaults.standard.string(forKey: "bonsai.githubToken")
    UserDefaults.standard.removeObject(forKey: "bonsai.githubToken")
    defer {
      if let previousToken {
        UserDefaults.standard.set(previousToken, forKey: "bonsai.githubToken")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.githubToken")
      }
    }

    let store = RepositoryStore()
    let request = GitHubRepositoryRequest(
      operation: .create,
      owner: "",
      name: "bonsai",
      repositoryDescription: "",
      isPrivate: false
    )
    store.gitHubRepositoryRequest = request

    await store.runGitHubRepositoryOperation(request)

    XCTAssertEqual(store.commandResult?.title, "Create GitHub repository")
    XCTAssertEqual(store.commandResult?.isError, true)
    XCTAssertEqual(store.commandResult?.output, "Add a GitHub personal access token in Settings first.")
    XCTAssertEqual(store.gitHubRepositoryRequest, request)
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
