import Foundation
import XCTest
@testable import Bonsai

final class ProcessRunnerTests: XCTestCase {
  func testCancellationTerminatesRunningProcess() async throws {
    let runner = ProcessRunner()
    let startedAt = Date()
    let task = Task {
      try await runner.runData("/bin/sleep", arguments: ["5"], currentDirectory: nil)
    }

    try await Task.sleep(nanoseconds: 100_000_000)
    task.cancel()

    do {
      _ = try await task.value
      XCTFail("Expected cancelled process to fail")
    } catch {
      XCTAssertLessThan(Date().timeIntervalSince(startedAt), 2)
    }
  }
}
