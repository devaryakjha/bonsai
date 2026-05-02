import Foundation
import XCTest

final class ReleaseScriptTests: XCTestCase {
  func testCheckCredentialsRejectsAppleDistributionIdentity() throws {
    let result = try runPackageRelease(
      arguments: ["--check-credentials"],
      environment: [
        "BONSAI_CODESIGN_IDENTITY": "Apple Distribution: Example, Inc. (TEAMID)",
        "BONSAI_NOTARY_PROFILE": "missing-profile"
      ]
    )

    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(
      result.output.contains("BONSAI_CODESIGN_IDENTITY must be a Developer ID Application identity"),
      result.output
    )
  }

  func testDoctorReportsInvalidCredentialStateWithoutPackaging() throws {
    let result = try runPackageRelease(
      arguments: ["--doctor"],
      environment: [
        "BONSAI_CODESIGN_IDENTITY": "Apple Distribution: Example, Inc. (TEAMID)",
        "BONSAI_NOTARY_PROFILE": "missing-profile",
        "BONSAI_NOTARY_KEYCHAIN": "/tmp/missing-bonsai-test.keychain-db"
      ]
    )

    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.output.contains("Bonsai release doctor"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_CODESIGN_IDENTITY: invalid prefix"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_NOTARY_PROFILE: could not be validated"), result.output)
    XCTAssertTrue(result.output.contains("Distribution credentials: not ready"), result.output)
    XCTAssertFalse(result.output.contains("Packaged "), result.output)
  }

  func testReleaseScriptDocumentsAndChecksArtifactVerifier() throws {
    let root = try packageRoot()
    let script = try String(
      contentsOf: root.appending(path: "script/package_release.sh"),
      encoding: .utf8
    )
    let help = try runPackageRelease(arguments: ["--help"]).output

    XCTAssertTrue(help.contains("--verify-artifacts"), help)
    XCTAssertTrue(help.contains("BONSAI_NOTARY_KEYCHAIN"), help)
    XCTAssertTrue(script.contains("verify_release_artifacts()"))
    XCTAssertTrue(script.contains("manifest archiveSHA256 mismatch"))
    XCTAssertTrue(script.contains("plutil -extract archiveSHA256 raw"))
  }

  func testReleaseWorkflowVerifiesArtifactsBeforeUploadAndCleansTemporaryKeychain() throws {
    let root = try packageRoot()
    let workflow = try String(
      contentsOf: root.appending(path: ".github/workflows/release.yml"),
      encoding: .utf8
    )
    let verifyRange = workflow.range(of: "name: Verify release artifacts")
    let uploadRange = workflow.range(of: "uses: actions/upload-artifact@v4")

    XCTAssertTrue(workflow.contains("environment: release"))
    XCTAssertTrue(workflow.contains("dist/release/Bonsai.zip"))
    XCTAssertTrue(workflow.contains("dist/release/Bonsai.release.plist"))
    XCTAssertTrue(workflow.contains("./script/package_release.sh --verify-artifacts"))
    XCTAssertNotNil(verifyRange)
    XCTAssertNotNil(uploadRange)
    XCTAssertLessThan(verifyRange?.lowerBound ?? workflow.endIndex, uploadRange?.lowerBound ?? workflow.startIndex)
    XCTAssertTrue(workflow.contains("if: always()"))
    XCTAssertTrue(workflow.contains("security delete-keychain \"$BONSAI_NOTARY_KEYCHAIN\""))
  }

  private func runPackageRelease(
    arguments: [String],
    environment overrides: [String: String] = [:]
  ) throws -> ProcessResult {
    let root = try packageRoot()
    let process = Process()
    let outputPipe = Pipe()
    let script = root.appending(path: "script/package_release.sh").path(percentEncoded: false)

    process.executableURL = URL(filePath: "/bin/bash")
    process.arguments = [script] + arguments
    process.currentDirectoryURL = root
    process.standardOutput = outputPipe
    process.standardError = outputPipe
    process.environment = ProcessInfo.processInfo.environment.merging(overrides) { _, new in new }

    try process.run()
    process.waitUntilExit()

    let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return ProcessResult(status: process.terminationStatus, output: output)
  }

  private func packageRoot() throws -> URL {
    var url = URL(filePath: FileManager.default.currentDirectoryPath, directoryHint: .isDirectory)
    while url.path(percentEncoded: false) != "/" {
      let package = url.appending(path: "Package.swift")
      let script = url.appending(path: "script/package_release.sh")
      if FileManager.default.fileExists(atPath: package.path(percentEncoded: false)),
         FileManager.default.fileExists(atPath: script.path(percentEncoded: false)) {
        return url
      }
      url.deleteLastPathComponent()
    }
    throw XCTSkip("Package root not found")
  }
}

private struct ProcessResult {
  var status: Int32
  var output: String
}
