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
    XCTAssertEqual(notifications[0].webURL?.absoluteString, "https://github.com/example/bonsai/pull/1")
    XCTAssertEqual(notifications[0].sidebarDetail, "example/bonsai - PullRequest")
  }

  func testNotificationWebURLFallsBackToRepository() {
    let notification = GitHubNotification(
      id: "1",
      unread: true,
      reason: "mention",
      updatedAt: "2026-05-02T00:00:00Z",
      subject: GitHubNotification.Subject(
        title: "Repository notice",
        type: "Repository",
        url: nil
      ),
      repository: GitHubNotification.Repository(fullName: "example/bonsai")
    )

    XCTAssertEqual(notification.webURL?.absoluteString, "https://github.com/example/bonsai")
  }

  func testNotificationWebURLConvertsIssueAndCommitAPIURLs() {
    let issue = GitHubNotification(
      id: "1",
      unread: true,
      reason: "mention",
      updatedAt: "2026-05-02T00:00:00Z",
      subject: GitHubNotification.Subject(
        title: "Issue",
        type: "Issue",
        url: "https://api.github.com/repos/example/bonsai/issues/42"
      ),
      repository: GitHubNotification.Repository(fullName: "example/bonsai")
    )
    let commit = GitHubNotification(
      id: "2",
      unread: true,
      reason: "mention",
      updatedAt: "2026-05-02T00:00:00Z",
      subject: GitHubNotification.Subject(
        title: "Commit",
        type: "Commit",
        url: "https://api.github.com/repos/example/bonsai/commits/abc123"
      ),
      repository: GitHubNotification.Repository(fullName: "example/bonsai")
    )

    XCTAssertEqual(issue.webURL?.absoluteString, "https://github.com/example/bonsai/issues/42")
    XCTAssertEqual(commit.webURL?.absoluteString, "https://github.com/example/bonsai/commits/abc123")
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

  func testGitHubRepositoryRequestNormalizesUserInput() {
    let request = GitHubRepositoryRequest(
      operation: .create,
      owner: "  example  ",
      name: "  bonsai  ",
      repositoryDescription: "  Native Git client  ",
      isPrivate: true
    )
    let emptyDescriptionRequest = GitHubRepositoryRequest(
      operation: .create,
      owner: "example",
      name: "bonsai",
      repositoryDescription: " \n ",
      isPrivate: false
    )

    XCTAssertEqual(request.normalizedOwner, "example")
    XCTAssertEqual(request.normalizedName, "bonsai")
    XCTAssertEqual(request.normalizedDescription, "Native Git client")
    XCTAssertNil(emptyDescriptionRequest.normalizedDescription)
  }

  func testGitHubRepositoryRequestValidationUsesNormalizedValues() {
    XCTAssertEqual(
      GitHubRepositoryRequest(
        operation: .create,
        owner: "",
        name: " \n ",
        repositoryDescription: "",
        isPrivate: false
      ).validationMessage,
      "Repository name is required."
    )
    XCTAssertEqual(
      GitHubRepositoryRequest(
        operation: .delete,
        owner: " ",
        name: "bonsai",
        repositoryDescription: "",
        isPrivate: false
      ).validationMessage,
      "Repository owner is required."
    )
    XCTAssertNil(GitHubRepositoryRequest(
      operation: .delete,
      owner: " example ",
      name: " bonsai ",
      repositoryDescription: "",
      isPrivate: false
    ).validationMessage)
  }

  @MainActor
  func testInvalidGitHubRepositoryRequestSurfacesCommandResultWithoutDismissingRequest() async {
    let previousToken = UserDefaults.standard.string(forKey: "bonsai.githubToken")
    UserDefaults.standard.set("test-token", forKey: "bonsai.githubToken")
    defer {
      if let previousToken {
        UserDefaults.standard.set(previousToken, forKey: "bonsai.githubToken")
      } else {
        UserDefaults.standard.removeObject(forKey: "bonsai.githubToken")
      }
    }

    let store = RepositoryStore()
    let request = GitHubRepositoryRequest(
      operation: .delete,
      owner: "",
      name: "bonsai",
      repositoryDescription: "",
      isPrivate: false
    )
    store.gitHubRepositoryRequest = request

    await store.runGitHubRepositoryOperation(request)

    XCTAssertEqual(store.commandResult?.title, "Delete GitHub repository")
    XCTAssertEqual(store.commandResult?.isError, true)
    XCTAssertEqual(store.commandResult?.output, "Repository owner is required.")
    XCTAssertEqual(store.errorMessage, "Repository owner is required.")
    XCTAssertEqual(store.gitHubRepositoryRequest, request)
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

  func testGitHubRepositoryTargetExposesWebURL() {
    let target = GitHubRepositoryTarget(owner: "example", name: "bonsai")

    XCTAssertEqual(target.webURL?.absoluteString, "https://github.com/example/bonsai")
  }

  func testGitHubRepositoryTargetExposesBranchWebURL() {
    let target = GitHubRepositoryTarget(owner: "example", name: "bonsai")

    XCTAssertEqual(
      target.branchWebURL("feature/dashboard polish")?.absoluteString,
      "https://github.com/example/bonsai/tree/feature/dashboard%20polish"
    )
  }

  func testGitHubRepositoryTargetExposesTagWebURL() {
    let target = GitHubRepositoryTarget(owner: "example", name: "bonsai")

    XCTAssertEqual(
      target.tagWebURL("release/v1.0 candidate")?.absoluteString,
      "https://github.com/example/bonsai/tree/release/v1.0%20candidate"
    )
  }

  func testRemoteExposesFirstGitHubRepositoryTarget() {
    let remote = GitRemote(
      name: "origin",
      fetchURL: "git@gitlab.com:example/other.git",
      pushURL: "git@github.com:example/bonsai.git"
    )

    XCTAssertEqual(remote.githubRepositoryTarget, GitHubRepositoryTarget(owner: "example", name: "bonsai"))
  }

  func testRemoteExposesFirstGitHubWebURL() {
    let remote = GitRemote(
      name: "origin",
      fetchURL: "git@gitlab.com:example/other.git",
      pushURL: "git@github.com:example/bonsai.git"
    )

    XCTAssertEqual(remote.githubWebURL?.absoluteString, "https://github.com/example/bonsai")
  }

  func testRemoteExposesGitHubBranchWebURL() {
    let remote = GitRemote(
      name: "origin",
      fetchURL: "https://github.com/example/bonsai.git",
      pushURL: nil
    )

    XCTAssertEqual(
      remote.githubBranchWebURL(branchName: "feature/dashboard polish")?.absoluteString,
      "https://github.com/example/bonsai/tree/feature/dashboard%20polish"
    )
  }

  @MainActor
  func testStoreTagWebURLPrefersOriginGitHubRemote() {
    let store = RepositoryStore()
    let tag = GitRef(name: "refs/tags/v1.0.0", shortName: "v1.0.0", objectName: "abc123", isHead: false, kind: .tag)
    store.snapshot.remotes = [
      GitRemote(name: "backup", fetchURL: "https://github.com/backup/bonsai.git", pushURL: nil),
      GitRemote(name: "origin", fetchURL: "https://github.com/example/bonsai.git", pushURL: nil)
    ]

    XCTAssertEqual(store.githubWebURL(forTag: tag)?.absoluteString, "https://github.com/example/bonsai/tree/v1.0.0")
  }

  @MainActor
  func testStoreTagWebURLFallsBackToFirstGitHubRemote() {
    let store = RepositoryStore()
    let tag = GitRef(name: "refs/tags/release/v1.0", shortName: "release/v1.0", objectName: "abc123", isHead: false, kind: .tag)
    store.snapshot.remotes = [
      GitRemote(name: "origin", fetchURL: "git@gitlab.com:example/bonsai.git", pushURL: nil),
      GitRemote(name: "backup", fetchURL: "git@github.com:backup/bonsai.git", pushURL: nil)
    ]

    XCTAssertEqual(store.githubWebURL(forTag: tag)?.absoluteString, "https://github.com/backup/bonsai/tree/release/v1.0")
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
