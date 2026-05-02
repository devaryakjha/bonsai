import Foundation

struct BinaryPreviewCopy: Equatable {
  var title: String
  var systemImage: String
  var statusLine: String

  init(isImage: Bool, statusTitle: String?) {
    let fileKind = isImage ? "image file" : "binary file"
    title = isImage ? "Image diff" : "Binary diff"
    systemImage = isImage ? "photo" : "doc"

    if let statusTitle, !statusTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      statusLine = "\(statusTitle) \(fileKind)"
    } else {
      statusLine = fileKind.prefix(1).uppercased() + fileKind.dropFirst()
    }
  }
}
