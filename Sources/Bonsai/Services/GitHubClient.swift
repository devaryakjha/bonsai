import Foundation

struct GitHubClient {
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

    var request = URLRequest(url: url)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw GitHubClientError.invalidResponse
    }
    guard (200..<300).contains(http.statusCode) else {
      throw GitHubClientError.httpStatus(http.statusCode)
    }

    return try JSONDecoder().decode([GitHubNotification].self, from: data)
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
