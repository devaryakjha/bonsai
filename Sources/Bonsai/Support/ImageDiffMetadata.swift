import AppKit
import Foundation

enum ImageDiffMetadata {
  static func metadata(for image: NSImage, data: Data) -> String {
    if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
      return metadata(width: cgImage.width, height: cgImage.height, byteCount: data.count)
    }

    return metadata(
      width: Int(image.size.width.rounded()),
      height: Int(image.size.height.rounded()),
      byteCount: data.count
    )
  }

  static func metadata(width: Int, height: Int, byteCount: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return "\(width) x \(height) - \(formatter.string(fromByteCount: Int64(byteCount)))"
  }
}
