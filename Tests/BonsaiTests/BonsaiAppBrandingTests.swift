import AppKit
import XCTest
@testable import Bonsai

final class BonsaiAppBrandingTests: XCTestCase {
  func testAboutPanelOptionsUseBonsaiIdentityAndIcon() {
    let icon = NSImage(size: NSSize(width: 32, height: 32))
    let options = BonsaiAppBranding.aboutPanelOptions(icon: icon)

    XCTAssertEqual(options[.applicationName] as? String, "Bonsai")
    XCTAssertTrue(options[.applicationIcon] as? NSImage === icon)
    XCTAssertEqual(
      (options[.credits] as? NSAttributedString)?.string,
      "A native Git client for macOS."
    )
  }

  func testBundledIconResourceNamesTrackTopologyMark() {
    XCTAssertEqual(BonsaiAppBranding.iconResourceName, "Bonsai")
    XCTAssertEqual(BonsaiAppBranding.markResourceName, "bonsai-worktree-topology")
  }
}
