import Foundation

enum TerminalLauncher {
  static let executableURL = URL(filePath: "/usr/bin/open")

  static func arguments(for directoryURL: URL) -> [String] {
    ["-a", "Terminal", directoryURL.path(percentEncoded: false)]
  }

  static func openDirectory(_ directoryURL: URL) throws {
    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments(for: directoryURL)
    try process.run()
  }
}
