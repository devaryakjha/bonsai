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
          .font(.bonsaiMetadata)
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
    HStack(spacing: InterfaceSpacing.panelHorizontal) {
      Image(systemName: "speedometer")
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: InterfaceSpacing.xSmall) {
        Text("Repository benchmark")
          .font(.headline)
          .lineLimit(1)
        HStack(spacing: InterfaceSpacing.medium) {
          Text(report.repositoryName)
            .lineLimit(1)
          Text(StaticDateText.time(report.generatedAt))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        }
        .font(.bonsaiMetadata)
        .foregroundStyle(.secondary)
      }

      Spacer(minLength: 12)
    }
  }

  private func benchmarkSection(title: String, rows: [BenchmarkRow]) -> some View {
    VStack(alignment: .leading, spacing: InterfaceSpacing.medium) {
      Text(title)
        .font(.bonsaiMetadata)
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
    HStack(alignment: .firstTextBaseline, spacing: InterfaceSpacing.panelHorizontal) {
      Image(systemName: row.systemImage)
        .foregroundStyle(.secondary)
        .bonsaiSidebarIconFrame()

      VStack(alignment: .leading, spacing: 2) {
        Text(row.title)
          .lineLimit(1)
        if let detail = row.detail {
          Text(detail)
            .font(.bonsaiMetadata)
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
    .padding(.vertical, InterfaceSpacing.panelVertical)
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
