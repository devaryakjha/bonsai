import Foundation

struct ProcessOutput {
  var stdout: String
  var stderr: String
  var exitCode: Int32
}

enum ProcessRunnerError: LocalizedError {
  case failed(command: String, stderr: String, exitCode: Int32)

  var errorDescription: String? {
    switch self {
    case let .failed(command, stderr, exitCode):
      return "\(command) exited with \(exitCode): \(stderr)"
    }
  }
}

struct ProcessRunner {
  func run(
    _ executable: String,
    arguments: [String],
    currentDirectory: URL?,
    standardInput: String? = nil,
    environment: [String: String]? = nil
  ) async throws -> ProcessOutput {
    try await Task.detached(priority: .userInitiated) {
      let process = Process()
      process.executableURL = URL(filePath: executable)
      process.arguments = arguments
      process.currentDirectoryURL = currentDirectory
      if let environment {
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
      }

      let stdout = Pipe()
      let stderr = Pipe()
      process.standardOutput = stdout
      process.standardError = stderr

      let stdin = Pipe()
      if standardInput != nil {
        process.standardInput = stdin
      }

      try process.run()
      if let standardInput {
        stdin.fileHandleForWriting.write(Data(standardInput.utf8))
        try? stdin.fileHandleForWriting.close()
      }
      process.waitUntilExit()

      let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
      let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
      let output = ProcessOutput(
        stdout: String(data: stdoutData, encoding: .utf8) ?? "",
        stderr: String(data: stderrData, encoding: .utf8) ?? "",
        exitCode: process.terminationStatus
      )

      if output.exitCode != 0 {
        let command = ([executable] + arguments).joined(separator: " ")
        throw ProcessRunnerError.failed(
          command: command,
          stderr: output.stderr.trimmingCharacters(in: .whitespacesAndNewlines),
          exitCode: output.exitCode
        )
      }

      return output
    }.value
  }
}
