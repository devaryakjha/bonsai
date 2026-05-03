import AppKit
import Foundation
import XCTest
@testable import Bonsai

@MainActor
final class DiffPerformanceSmokeTests: XCTestCase {
  func testLargeHistoryAndDiffPerformanceSmoke() async throws {
    guard ProcessInfo.processInfo.environment["BONSAI_PERF_SMOKE"] == "1" else {
      return
    }

    let client = GitClient()
    let repoURL = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-perf-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: repoURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: repoURL) }

    _ = try await client.git(["init"], in: repoURL)
    _ = try await client.git(["branch", "-M", "main"], in: repoURL)
    _ = try await client.git(["config", "user.name", "Bonsai Perf"], in: repoURL)
    _ = try await client.git(["config", "user.email", "perf@example.test"], in: repoURL)

    let imageURL = repoURL.appending(path: "image.png")
    let firstImage = try XCTUnwrap(Self.pngData(width: 512, height: 512, seed: 40))
    let secondImage = try XCTUnwrap(Self.pngData(width: 512, height: 512, seed: 90))
    try firstImage.write(to: imageURL, options: .atomic)
    _ = try await client.git(["add", "image.png"], in: repoURL)
    _ = try await client.git(["commit", "-m", "Image baseline"], in: repoURL)

    for index in 1...319 {
      _ = try await client.git(["commit", "--allow-empty", "-m", "Commit \(index)"], in: repoURL)
    }
    try secondImage.write(to: imageURL, options: .atomic)

    let repository = GitRepository(path: repoURL.path(percentEncoded: false))
    let historyStart = Date()
    let commits = try await client.commits(in: repository)
    let historyMilliseconds = elapsedMilliseconds(since: historyStart)

    let status = try await client.status(in: repository)
    let imageEntry = try XCTUnwrap(status.first { $0.path == "image.png" })
    let imageStart = Date()
    let imageSnapshot = await client.imageDiffForWorkingTreeFile(imageEntry, in: repository)
    let oldImageData = try XCTUnwrap(imageSnapshot.oldData)
    let newImageData = try XCTUnwrap(imageSnapshot.newData)
    let oldImage = try XCTUnwrap(NSImage(data: oldImageData))
    let newImage = try XCTUnwrap(NSImage(data: newImageData))
    let oldImageMetadata = ImageDiffMetadata.metadata(for: oldImage, data: oldImageData)
    let newImageMetadata = ImageDiffMetadata.metadata(for: newImage, data: newImageData)
    let imageMilliseconds = elapsedMilliseconds(since: imageStart)

    let largeDiff = Self.largeReplacementDiff(lineCount: 12_000)
    let parseStart = Date()
    let store = RepositoryStore()
    store.diffText = largeDiff
    let parseMilliseconds = elapsedMilliseconds(since: parseStart)

    XCTAssertEqual(commits.count, 300)
    XCTAssertEqual(store.diffHunks.count, 1)
    XCTAssertTrue(store.diffLineChanges.isEmpty)
    XCTAssertEqual(store.splitDiff.oldLines.filter { $0.text.hasPrefix("-old") }.count, 12_000)
    XCTAssertEqual(store.splitDiff.newLines.filter { $0.text.hasPrefix("+new") }.count, 12_000)
    XCTAssertEqual(imageSnapshot.oldData, firstImage)
    XCTAssertEqual(imageSnapshot.newData, secondImage)
    XCTAssertTrue(oldImageMetadata.contains("512 x 512"))
    XCTAssertTrue(newImageMetadata.contains("512 x 512"))

    print(
      """
      BonsaiPerfSmoke history_commits=\(commits.count) history_ms=\(historyMilliseconds) \
      diff_lines=24000 parse_ms=\(parseMilliseconds) image_ms=\(imageMilliseconds)
      """
    )

    XCTAssertLessThan(historyMilliseconds, budget(named: "BONSAI_PERF_HISTORY_MS", defaultValue: 1_000))
    XCTAssertLessThan(parseMilliseconds, budget(named: "BONSAI_PERF_DIFF_PARSE_MS", defaultValue: 500))
    XCTAssertLessThan(imageMilliseconds, budget(named: "BONSAI_PERF_IMAGE_MS", defaultValue: 1_000))
  }

  private func elapsedMilliseconds(since start: Date) -> Int {
    Int(Date().timeIntervalSince(start) * 1_000)
  }

  private func budget(named name: String, defaultValue: Int) -> Int {
    guard let value = ProcessInfo.processInfo.environment[name],
          let budget = Int(value) else {
      return defaultValue
    }
    return budget
  }

  private static func largeReplacementDiff(lineCount: Int) -> String {
    let deleted = (1...lineCount).map { "-old \($0)" }.joined(separator: "\n")
    let added = (1...lineCount).map { "+new \($0)" }.joined(separator: "\n")
    return """
    diff --git a/Large.swift b/Large.swift
    index 1111111..2222222 100644
    --- a/Large.swift
    +++ b/Large.swift
    @@ -1,\(lineCount) +1,\(lineCount) @@
    \(deleted)
    \(added)
    """
  }

  private static func pngData(width: Int, height: Int, seed: UInt8) -> Data? {
    guard let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: width,
      pixelsHigh: height,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: width * 4,
      bitsPerPixel: 32
    ), let pixels = bitmap.bitmapData else {
      return nil
    }

    for y in 0..<height {
      for x in 0..<width {
        let offset = (y * width + x) * 4
        pixels[offset] = UInt8((x + Int(seed)) % 256)
        pixels[offset + 1] = UInt8((y + Int(seed)) % 256)
        pixels[offset + 2] = UInt8((x + y + Int(seed)) % 256)
        pixels[offset + 3] = 255
      }
    }

    return bitmap.representation(using: .png, properties: [:])
  }
}
