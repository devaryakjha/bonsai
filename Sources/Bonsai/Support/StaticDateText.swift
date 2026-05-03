import Foundation

enum StaticDateText {
  static func relativeOrDate(_ date: Date, now: Date = Date()) -> String {
    let seconds = max(Int(now.timeIntervalSince(date)), 0)
    if seconds < 60 {
      return seconds <= 1 ? "Just now" : "\(seconds)s ago"
    }
    if seconds < 3_600 {
      return "\(seconds / 60)m ago"
    }
    if Calendar.current.isDateInToday(date) {
      return time(date)
    }
    return self.date(date)
  }

  static func date(_ date: Date) -> String {
    date.formatted(.dateTime.year().month(.abbreviated).day())
  }

  static func time(_ date: Date) -> String {
    date.formatted(.dateTime.hour().minute())
  }

  static func timestamp(_ date: Date) -> String {
    date.formatted(.dateTime.year().month(.abbreviated).day().hour().minute())
  }
}
