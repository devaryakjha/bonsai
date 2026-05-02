import XCTest
@testable import Bonsai

final class TerminalLauncherTests: XCTestCase {
  func testTerminalLauncherKeepsDirectoryPathAsSingleArgument() {
    let url = URL(filePath: "/Users/arya/projects/with space", directoryHint: .isDirectory)

    XCTAssertEqual(TerminalLauncher.executableURL.path(percentEncoded: false), "/usr/bin/open")
    XCTAssertEqual(TerminalLauncher.arguments(for: url), [
      "-a",
      "Terminal",
      "/Users/arya/projects/with space/"
    ])
  }
}
