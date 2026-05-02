import AppKit
import XCTest
@testable import Bonsai

final class ImageDiffMetadataTests: XCTestCase {
  func testMetadataUsesDecodedPixelDimensions() throws {
    let representation = try XCTUnwrap(NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: 2,
      pixelsHigh: 1,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    ))
    let image = NSImage(size: NSSize(width: 1, height: 1))
    image.addRepresentation(representation)
    let data = Data(repeating: 0, count: 24)

    let metadata = ImageDiffMetadata.metadata(for: image, data: data)

    XCTAssertTrue(metadata.hasPrefix("2 x 1 - "))
  }

  func testMetadataFormatsFallbackDimensionsAndFileSize() {
    XCTAssertEqual(ImageDiffMetadata.metadata(width: 12, height: 8, byteCount: 1_024), "12 x 8 - 1 KB")
  }
}
