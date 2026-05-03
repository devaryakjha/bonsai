import Foundation

enum CodeAgentPromptPreferences {
  static let commitMessageRequestKey = "bonsai.codeAgent.commitMessageRequest"
  static let branchReviewRequestKey = "bonsai.codeAgent.branchReviewRequest"

  static let defaultCommitMessageRequest = "Write a Git commit message for the staged changes below."
  static let defaultBranchReviewRequest = "Review the current Git branch diff."

  static func commitMessageRequest(defaults: UserDefaults = .standard) -> String {
    resolvedRequest(
      defaults.string(forKey: commitMessageRequestKey),
      fallback: defaultCommitMessageRequest
    )
  }

  static func branchReviewRequest(defaults: UserDefaults = .standard) -> String {
    resolvedRequest(
      defaults.string(forKey: branchReviewRequestKey),
      fallback: defaultBranchReviewRequest
    )
  }

  static func resolvedRequest(_ request: String?, fallback: String) -> String {
    let trimmed = request?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? fallback : trimmed
  }
}
