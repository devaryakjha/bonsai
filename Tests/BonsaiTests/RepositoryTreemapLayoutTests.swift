import CoreGraphics
import XCTest
@testable import Bonsai

final class RepositoryTreemapLayoutTests: XCTestCase {
  func testPositionedTilesStayInsideBoundsAndPreserveOrder() {
    let tiles = [
      RepositoryTreemapTile(title: "Sources", path: "Sources/", bytes: 60, fileCount: 3),
      RepositoryTreemapTile(title: "Assets", path: "Assets/", bytes: 30, fileCount: 2),
      RepositoryTreemapTile(title: "README.md", path: "README.md", bytes: 10, fileCount: 1)
    ]
    let bounds = CGRect(x: 0, y: 0, width: 100, height: 50)

    let positioned = RepositoryTreemapLayout.positionedTiles(tiles, in: bounds)

    XCTAssertEqual(positioned.map(\.tile.title), ["Sources", "Assets", "README.md"])
    XCTAssertEqual(positioned.count, 3)
    XCTAssertTrue(positioned.allSatisfy { bounds.contains($0.rect) })
    XCTAssertTrue(positioned.allSatisfy { $0.rect.width >= 0 && $0.rect.height >= 0 })
  }

  func testPositionedTilesIgnoreZeroByteEntries() {
    let tiles = [
      RepositoryTreemapTile(title: "Empty", path: "Empty/", bytes: 0, fileCount: 1),
      RepositoryTreemapTile(title: "Sources", path: "Sources/", bytes: 100, fileCount: 3)
    ]

    let positioned = RepositoryTreemapLayout.positionedTiles(tiles, in: CGRect(x: 0, y: 0, width: 120, height: 80))

    XCTAssertEqual(positioned.count, 1)
    XCTAssertEqual(positioned.first?.tile.title, "Sources")
  }
}
