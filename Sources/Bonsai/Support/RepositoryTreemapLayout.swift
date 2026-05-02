import CoreGraphics

struct RepositoryTreemapLayout {
  struct PositionedTile: Hashable {
    var tile: RepositoryTreemapTile
    var rect: CGRect
  }

  static func positionedTiles(_ tiles: [RepositoryTreemapTile], in bounds: CGRect) -> [PositionedTile] {
    let positiveTiles = tiles.filter { $0.bytes > 0 }
    let totalBytes = positiveTiles.reduce(0) { $0 + $1.bytes }
    guard totalBytes > 0, bounds.width > 0, bounds.height > 0 else { return [] }

    var remainingRect = bounds
    var remainingBytes = totalBytes
    var positioned: [PositionedTile] = []

    for tile in positiveTiles.dropLast() {
      let fraction = CGFloat(tile.bytes) / CGFloat(remainingBytes)
      let tileRect: CGRect
      if remainingRect.width >= remainingRect.height {
        let width = max(remainingRect.width * fraction, 0)
        tileRect = CGRect(x: remainingRect.minX, y: remainingRect.minY, width: width, height: remainingRect.height)
        remainingRect = CGRect(
          x: remainingRect.minX + width,
          y: remainingRect.minY,
          width: max(remainingRect.width - width, 0),
          height: remainingRect.height
        )
      } else {
        let height = max(remainingRect.height * fraction, 0)
        tileRect = CGRect(x: remainingRect.minX, y: remainingRect.minY, width: remainingRect.width, height: height)
        remainingRect = CGRect(
          x: remainingRect.minX,
          y: remainingRect.minY + height,
          width: remainingRect.width,
          height: max(remainingRect.height - height, 0)
        )
      }
      positioned.append(PositionedTile(tile: tile, rect: displayRect(tileRect)))
      remainingBytes -= tile.bytes
    }

    if let last = positiveTiles.last {
      positioned.append(PositionedTile(tile: last, rect: displayRect(remainingRect)))
    }

    return positioned
  }

  private static func displayRect(_ rect: CGRect) -> CGRect {
    rect.insetBy(dx: min(2, rect.width / 2), dy: min(2, rect.height / 2))
  }
}
