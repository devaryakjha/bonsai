import XCTest
@testable import Bonsai

final class FileOpenLauncherTests: XCTestCase {
  func testFileOpenLauncherResolvesRepositoryRelativePath() {
    let repository = GitRepository(path: "/Users/arya/projects/bonsai")
    let url = FileOpenLauncher.targetURL(repository: repository, path: "Sources/Bonsai/App/BonsaiApp.swift")

    XCTAssertEqual(url.path(percentEncoded: false), "/Users/arya/projects/bonsai/Sources/Bonsai/App/BonsaiApp.swift")
  }

  func testExternalEditorTitlesAndBundleIdentifiersAreStable() {
    XCTAssertEqual(ExternalEditor.xcode.commandTitle, "Open in Xcode")
    XCTAssertEqual(ExternalEditor.visualStudioCode.bundleIdentifiers, ["com.microsoft.VSCode", "com.microsoft.VSCodeInsiders"])
    XCTAssertEqual(ExternalEditor.zed.bundleIdentifiers, ["dev.zed.Zed", "dev.zed.Zed-Preview"])
    XCTAssertEqual(ExternalEditor.bbedit.bundleIdentifiers, ["com.barebones.bbedit"])
  }
}
