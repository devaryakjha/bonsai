import Foundation

enum GitCommandOutputFormatter {
  static let verboseGitOutputKey = "bonsai.verboseGitOutput"

  static func formattedOutput(arguments: [String], output: ProcessOutput, verbose: Bool) -> String {
    let combinedOutput = [output.stdout, output.stderr]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
    guard verbose else { return combinedOutput }

    let command = "git " + arguments.map(escapedArgument).joined(separator: " ")
    if combinedOutput.isEmpty {
      return command
    }
    return "\(command)\n\(combinedOutput)"
  }

  private static func escapedArgument(_ argument: String) -> String {
    guard argument.rangeOfCharacter(from: .whitespacesAndNewlines) != nil else {
      return argument
    }

    return "'\(argument.replacingOccurrences(of: "'", with: "'\\''"))'"
  }
}
