import Foundation

struct ProcessOutput {
  var stdout: String
  var stderr: String
  var exitCode: Int32
}

struct ProcessDataOutput {
  var stdout: Data
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

private final class RunningProcessBox: @unchecked Sendable {
  private let lock = NSLock()
  private var process: Process?

  func set(_ process: Process) {
    lock.lock()
    self.process = process
    lock.unlock()
  }

  func clear(_ process: Process) {
    lock.lock()
    if self.process === process {
      self.process = nil
    }
    lock.unlock()
  }

  func terminate() {
    lock.lock()
    process?.terminate()
    lock.unlock()
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
    let output = try await runData(
      executable,
      arguments: arguments,
      currentDirectory: currentDirectory,
      standardInput: standardInput,
      environment: environment
    )
    return ProcessOutput(
      stdout: String(data: output.stdout, encoding: .utf8) ?? "",
      stderr: output.stderr,
      exitCode: output.exitCode
    )
  }

  func runData(
    _ executable: String,
    arguments: [String],
    currentDirectory: URL?,
    standardInput: String? = nil,
    environment: [String: String]? = nil
  ) async throws -> ProcessDataOutput {
    let processBox = RunningProcessBox()
    let task = Task.detached(priority: .userInitiated) {
      try Task.checkCancellation()

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
      processBox.set(process)
      if Task.isCancelled {
        process.terminate()
      }
      if let standardInput {
        stdin.fileHandleForWriting.write(Data(standardInput.utf8))
        try? stdin.fileHandleForWriting.close()
      }
      process.waitUntilExit()
      processBox.clear(process)
      try Task.checkCancellation()

      let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
      let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
      let output = ProcessDataOutput(
        stdout: stdoutData,
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
    }
    return try await withTaskCancellationHandler {
      try await task.value
    } onCancel: {
      task.cancel()
      processBox.terminate()
    }
  }
}
