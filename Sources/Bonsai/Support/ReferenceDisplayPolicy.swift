enum ReferenceDisplayPolicy {
  static let defaultLimit = 20

  static func visibleItems<T>(_ items: [T], showAll: Bool) -> [T] {
    showAll ? items : Array(items.prefix(defaultLimit))
  }

  static func hiddenCount<T>(_ items: [T], showAll: Bool) -> Int {
    showAll ? 0 : max(0, items.count - defaultLimit)
  }
}
