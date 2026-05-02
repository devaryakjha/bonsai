import Foundation

enum FilePreviewSupport {
  private static let imageExtensions: Set<String> = [
    "png", "jpg", "jpeg", "gif", "tif", "tiff", "bmp", "webp", "heic", "heif", "ico"
  ]

  static func isImagePath(_ path: String) -> Bool {
    let ext = URL(filePath: path).pathExtension.lowercased()
    return imageExtensions.contains(ext)
  }

  static func isBinaryDiff(_ diffText: String) -> Bool {
    diffText
      .split(separator: "\n", omittingEmptySubsequences: true)
      .contains { line in
        line.hasPrefix("Binary files ") && line.hasSuffix(" differ")
      }
  }
}
