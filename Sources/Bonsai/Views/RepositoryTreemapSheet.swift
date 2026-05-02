import SwiftUI

struct RepositoryTreemapSheet: View {
  var report: RepositoryTreemapReport
  var onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      header
        .padding(.horizontal, 20)
        .padding(.vertical, 16)

      Divider()

      VStack(alignment: .leading, spacing: 14) {
        RepositoryTreemapCanvas(report: report)
          .frame(height: 300)

        ScrollView {
          VStack(spacing: 0) {
            ForEach(Array(report.tiles.enumerated()), id: \.element.id) { index, tile in
              RepositoryTreemapDetailRow(
                tile: tile,
                share: shareLabel(for: tile),
                color: RepositoryTreemapPalette.color(at: index)
              )
              if tile.id != report.tiles.last?.id {
                Divider()
                  .padding(.leading, 32)
              }
            }
          }
        }
      }
      .padding(20)

      Divider()

      HStack {
        Text("\(report.totalSizeLabel) across \(fileCountLabel)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Spacer()
        Button("Close") {
          onClose()
        }
        .keyboardShortcut(.cancelAction)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
    }
    .frame(width: 640, height: 620)
  }

  private var header: some View {
    HStack(spacing: 12) {
      Image(systemName: "square.grid.3x3.fill")
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: 3) {
        Text("Repository treemap")
          .font(.headline)
          .lineLimit(1)
        HStack(spacing: 8) {
          Text(report.repositoryName)
            .lineLimit(1)
          Text(report.generatedAt, style: .time)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Spacer(minLength: 12)
    }
  }

  private var fileCountLabel: String {
    let count = report.tiles.reduce(0) { $0 + $1.fileCount }
    return count == 1 ? "1 file" : "\(count.formatted()) files"
  }

  private func shareLabel(for tile: RepositoryTreemapTile) -> String {
    guard report.totalBytes > 0 else { return "0%" }
    let share = Double(tile.bytes) / Double(report.totalBytes)
    return share.formatted(.percent.precision(.fractionLength(0...1)))
  }
}

private struct RepositoryTreemapCanvas: View {
  var report: RepositoryTreemapReport

  var body: some View {
    GeometryReader { proxy in
      let positioned = RepositoryTreemapLayout.positionedTiles(
        report.tiles,
        in: CGRect(origin: .zero, size: proxy.size)
      )

      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 6)
          .fill(Color(nsColor: .separatorColor).opacity(0.25))

        ForEach(Array(positioned.enumerated()), id: \.element.tile.id) { index, positionedTile in
          RepositoryTreemapTileView(
            tile: positionedTile.tile,
            share: shareLabel(for: positionedTile.tile),
            color: RepositoryTreemapPalette.color(at: index),
            rect: positionedTile.rect
          )
        }
      }
    }
  }

  private func shareLabel(for tile: RepositoryTreemapTile) -> String {
    guard report.totalBytes > 0 else { return "0%" }
    let share = Double(tile.bytes) / Double(report.totalBytes)
    return share.formatted(.percent.precision(.fractionLength(0...1)))
  }
}

private struct RepositoryTreemapTileView: View {
  var tile: RepositoryTreemapTile
  var share: String
  var color: Color
  var rect: CGRect

  var body: some View {
    RoundedRectangle(cornerRadius: 5)
      .fill(color)
      .overlay(alignment: .topLeading) {
        if rect.width >= 92, rect.height >= 58 {
          VStack(alignment: .leading, spacing: 3) {
            Text(tile.title)
              .font(.caption)
              .fontWeight(.semibold)
              .lineLimit(1)
            Text("\(tile.sizeLabel), \(share)")
              .font(.caption2)
              .lineLimit(1)
          }
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
          .padding(8)
        }
      }
      .help("\(tile.path) • \(tile.sizeLabel) • \(tile.fileCountLabel)")
      .frame(width: max(rect.width, 0), height: max(rect.height, 0))
      .position(x: rect.midX, y: rect.midY)
  }
}

private struct RepositoryTreemapDetailRow: View {
  var tile: RepositoryTreemapTile
  var share: String
  var color: Color

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      RoundedRectangle(cornerRadius: 3)
        .fill(color)
        .frame(width: 14, height: 14)

      VStack(alignment: .leading, spacing: 2) {
        Text(tile.title)
          .lineLimit(1)
        Text(tile.path)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 16)

      VStack(alignment: .trailing, spacing: 2) {
        Text(tile.sizeLabel)
          .font(.body.monospacedDigit())
          .lineLimit(1)
        Text("\(share), \(tile.fileCountLabel)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.vertical, 8)
  }
}

private enum RepositoryTreemapPalette {
  static func color(at index: Int) -> Color {
    colors[index % colors.count]
  }

  private static let colors: [Color] = [
    Color(nsColor: .systemBlue),
    Color(nsColor: .systemGreen),
    Color(nsColor: .systemOrange),
    Color(nsColor: .systemPurple),
    Color(nsColor: .systemPink),
    Color(nsColor: .systemTeal),
    Color(nsColor: .systemIndigo),
    Color(nsColor: .systemBrown)
  ]
}
