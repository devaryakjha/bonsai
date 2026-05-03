import AppKit
import SwiftUI

struct AppKitSegmentedControl<Option: Hashable>: NSViewRepresentable {
  var options: [Option]
  @Binding var selection: Option
  var label: String
  var controlSize: NSControl.ControlSize = .regular
  var title: (Option) -> String

  func makeCoordinator() -> Coordinator {
    Coordinator(selection: $selection)
  }

  func makeNSView(context: Context) -> NSSegmentedControl {
    let control = NSSegmentedControl()
    control.trackingMode = .selectOne
    control.segmentStyle = .rounded
    control.controlSize = controlSize
    control.target = context.coordinator
    control.action = #selector(Coordinator.selectionChanged(_:))
    control.setContentHuggingPriority(.required, for: .horizontal)
    control.setContentCompressionResistancePriority(.required, for: .horizontal)
    configure(control, context: context)
    return control
  }

  func updateNSView(_ control: NSSegmentedControl, context: Context) {
    context.coordinator.selection = $selection
    configure(control, context: context)
  }

  private func configure(_ control: NSSegmentedControl, context: Context) {
    let titles = options.map(title)
    if context.coordinator.titles != titles {
      control.segmentCount = titles.count
      for index in titles.indices {
        control.setLabel(titles[index], forSegment: index)
      }
      context.coordinator.titles = titles
    }
    context.coordinator.options = options
    control.controlSize = controlSize
    control.setAccessibilityLabel(label)
    control.selectedSegment = options.firstIndex(of: selection) ?? -1
  }

  final class Coordinator: NSObject {
    var selection: Binding<Option>
    var options: [Option] = []
    var titles: [String] = []

    init(selection: Binding<Option>) {
      self.selection = selection
    }

    @objc func selectionChanged(_ sender: NSSegmentedControl) {
      guard options.indices.contains(sender.selectedSegment) else { return }
      selection.wrappedValue = options[sender.selectedSegment]
    }
  }
}
