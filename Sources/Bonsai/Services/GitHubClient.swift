import Foundation

struct GitHubClient {
  func createRepository(token: String, name: String, description: String?, isPrivate: Bool) async throws -> GitHubRepository {
    guard let url = URL(string: "https://api.github.com/user/repos") else {
      throw GitHubClientError.invalidURL
    }

    var body: [String: EncodableValue] = [
      "name": .string(name),
      "private": .bool(isPrivate)
    ]
    if let description, !description.isEmpty {
      body["description"] = .string(description)
    }

    var request = authenticatedRequest(url: url, token: token)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)
    try validate(response)
    return try JSONDecoder().decode(GitHubRepository.self, from: data)
  }

  func deleteRepository(token: String, owner: String, name: String) async throws {
    guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(name)") else {
      throw GitHubClientError.invalidURL
    }

    var request = authenticatedRequest(url: url, token: token)
    request.httpMethod = "DELETE"

    let (_, response) = try await URLSession.shared.data(for: request)
    try validate(response)
  }

  func notifications(token: String) async throws -> [GitHubNotification] {
    guard var components = URLComponents(string: "https://api.github.com/notifications") else {
      throw GitHubClientError.invalidURL
    }
    components.queryItems = [
      URLQueryItem(name: "all", value: "false"),
      URLQueryItem(name: "participating", value: "false")
    ]
    guard let url = components.url else {
      throw GitHubClientError.invalidURL
    }

    let request = authenticatedRequest(url: url, token: token)

    let (data, response) = try await URLSession.shared.data(for: request)
    try validate(response)

    return try JSONDecoder().decode([GitHubNotification].self, from: data)
  }

  func markNotificationsRead(token: String, lastReadAt: Date = Date()) async throws {
    guard let url = URL(string: "https://api.github.com/notifications") else {
      throw GitHubClientError.invalidURL
    }

    var request = authenticatedRequest(url: url, token: token)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode([
      "last_read_at": ISO8601DateFormatter().string(from: lastReadAt)
    ])

    let (_, response) = try await URLSession.shared.data(for: request)
    try validate(response)
  }

  private func authenticatedRequest(url: URL, token: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
  }

  private func validate(_ response: URLResponse) throws {
    guard let http = response as? HTTPURLResponse else {
      throw GitHubClientError.invalidResponse
    }
    guard (200..<300).contains(http.statusCode) else {
      throw GitHubClientError.httpStatus(http.statusCode)
    }
  }
}

private enum EncodableValue: Encodable {
  case string(String)
  case bool(Bool)

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .string(value):
      try container.encode(value)
    case let .bool(value):
      try container.encode(value)
    }
  }
}

enum GitHubClientError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpStatus(Int)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "GitHub notifications URL is invalid."
    case .invalidResponse:
      return "GitHub returned an invalid response."
    case let .httpStatus(status):
      return "GitHub notifications request failed with HTTP \(status)."
    }
  }
}
