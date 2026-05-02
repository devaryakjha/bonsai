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

  func testPlanValidationBlocksFirstSquashOrFixup() {
    let squashPlan = InteractiveRebasePlan(
      upstream: "abc123^",
      items: [
        InteractiveRebaseItem(action: .squash, hash: "abc123", shortHash: "abc123", subject: "First"),
        InteractiveRebaseItem(action: .pick, hash: "def456", shortHash: "def456", subject: "Second")
      ]
    )
    let fixupPlan = InteractiveRebasePlan(
      upstream: "abc123^",
      items: [
        InteractiveRebaseItem(action: .fixup, hash: "abc123", shortHash: "abc123", subject: "First"),
        InteractiveRebaseItem(action: .pick, hash: "def456", shortHash: "def456", subject: "Second")
      ]
    )

    XCTAssertEqual(squashPlan.validationMessage, "Squash requires a previous commit.")
    XCTAssertFalse(squashPlan.canStart)
    XCTAssertEqual(fixupPlan.validationMessage, "Fixup requires a previous commit.")
    XCTAssertFalse(fixupPlan.canStart)
  }

  func testPlanValidationAllowsFirstPickRewordEditOrDrop() {
    for action in [RebaseTodoAction.pick, .reword, .edit, .drop] {
      let plan = InteractiveRebasePlan(
        upstream: "abc123^",
        items: [
          InteractiveRebaseItem(action: action, hash: "abc123", shortHash: "abc123", subject: "First")
        ]
      )

      XCTAssertNil(plan.validationMessage)
      XCTAssertTrue(plan.canStart)
    }
  }
}
