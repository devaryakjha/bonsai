import SwiftUI

struct RepositoryBenchmarkSheet: View {
  var report: RepositoryBenchmarkReport
  var onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      header
        .padding(.horizontal, 20)
        .padding(.vertical, 16)

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          benchmarkSection(title: "Repository", rows: report.metrics.map(BenchmarkRow.metric))
          benchmarkSection(title: "Timings", rows: report.timings.map(BenchmarkRow.timing))
        }
        .padding(20)
      }

      Divider()

      HStack {
        Text("Measured \(report.totalMeasuredMilliseconds.formatted()) ms total")
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
    .frame(width: 560, height: 520)
  }

  private var header: some View {
    HStack(spacing: 12) {
      Image(systemName: "speedometer")
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: 3) {
        Text("Repository benchmark")
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

  private func benchmarkSection(title: String, rows: [BenchmarkRow]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      VStack(spacing: 0) {
        ForEach(rows) { row in
          BenchmarkDataRow(row: row)
          if row.id != rows.last?.id {
            Divider()
              .padding(.leading, 32)
          }
        }
      }
    }
  }
}

private struct BenchmarkDataRow: View {
  var row: BenchmarkRow

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Image(systemName: row.systemImage)
        .foregroundStyle(.secondary)
        .frame(width: 20)

      VStack(alignment: .leading, spacing: 2) {
        Text(row.title)
          .lineLimit(1)
        if let detail = row.detail {
          Text(detail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 16)

      Text(row.value)
        .font(.body.monospacedDigit())
        .foregroundStyle(.primary)
        .lineLimit(1)
    }
    .padding(.vertical, 8)
  }
}

private struct BenchmarkRow: Identifiable, Hashable {
  var id: String
  var title: String
  var value: String
  var detail: String?
  var systemImage: String

  static func metric(_ metric: RepositoryBenchmarkMetric) -> BenchmarkRow {
    BenchmarkRow(
      id: metric.id,
      title: metric.title,
      value: metric.value,
      detail: metric.detail,
      systemImage: metric.systemImage
    )
  }

  static func timing(_ timing: RepositoryBenchmarkTiming) -> BenchmarkRow {
    BenchmarkRow(
      id: timing.id,
      title: timing.title,
      value: timing.value,
      detail: timing.detail,
      systemImage: "timer"
    )
  }
}
