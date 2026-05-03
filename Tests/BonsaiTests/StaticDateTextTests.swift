import Foundation
import XCTest
@testable import Bonsai

final class StaticDateTextTests: XCTestCase {
  func testRelativeTextUsesSecondsOnlyForSubMinuteDates() {
    let now = Date(timeIntervalSince1970: 1_000)

    XCTAssertEqual(StaticDateText.relativeOrDate(Date(timeIntervalSince1970: 999), now: now), "Just now")
    XCTAssertEqual(StaticDateText.relativeOrDate(Date(timeIntervalSince1970: 970), now: now), "30s ago")
    XCTAssertEqual(StaticDateText.relativeOrDate(Date(timeIntervalSince1970: 880), now: now), "2m ago")
  }
}
