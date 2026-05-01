import XCTest
@testable import Bonsai

final class InteractiveRebasePlanTests: XCTestCase {
  func testTodoTextPreservesOrderAndActions() {
    let plan = InteractiveRebasePlan(
      upstream: "abc123^",
      items: [
        InteractiveRebaseItem(action: .pick, hash: "abc123", shortHash: "abc123", subject: "First"),
        InteractiveRebaseItem(action: .squash, hash: "def456", shortHash: "def456", subject: "Second"),
        InteractiveRebaseItem(action: .edit, hash: "fedcba", shortHash: "fedcba", subject: "Third")
      ]
    )

    XCTAssertEqual(plan.todoText, """
    pick abc123 First
    squash def456 Second
    edit fedcba Third

    """)
  }
}
