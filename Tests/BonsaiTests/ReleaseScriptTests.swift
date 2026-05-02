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
    XCTAssertTrue(help.contains("--github-doctor"), help)
    XCTAssertTrue(help.contains("BONSAI_NOTARY_KEYCHAIN"), help)
    XCTAssertTrue(script.contains("verify_release_artifacts()"))
    XCTAssertTrue(script.contains("github_release_doctor()"))
    XCTAssertTrue(script.contains("manifest archiveSHA256 mismatch"))
    XCTAssertTrue(script.contains("plutil -extract archiveSHA256 raw"))
  }

  func testGitHubDoctorReportsMissingEnvironmentSecretsWithMockedGh() throws {
    let fakeBin = try makeFakeGitHubCLI(
      environmentSecrets: [
        "BONSAI_CODESIGN_IDENTITY",
        "BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64"
      ],
      repositorySecrets: []
    )
    let path = [
      fakeBin.path(percentEncoded: false),
      ProcessInfo.processInfo.environment["PATH"] ?? ""
    ].joined(separator: ":")
    let result = try runPackageRelease(
      arguments: ["--github-doctor"],
      environment: ["PATH": path]
    )

    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(result.output.contains("Bonsai GitHub release doctor"), result.output)
    XCTAssertTrue(result.output.contains("release environment: available"), result.output)
    XCTAssertTrue(result.output.contains("required reviewers: devaryakjha"), result.output)
    XCTAssertTrue(result.output.contains("release runner: jarvis-bonsai online"), result.output)
    XCTAssertTrue(result.output.contains("runner label jarvis: available"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_CODESIGN_IDENTITY: configured"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_NOTARY_TEAM_ID: missing"), result.output)
    XCTAssertTrue(result.output.contains("repository-level release secrets: none"), result.output)
    XCTAssertTrue(result.output.contains("GitHub release configuration: not ready"), result.output)
    XCTAssertFalse(result.output.contains("Packaged "), result.output)
  }

  func testCIWorkflowRunsArtifactVerifierAfterArchiveVerifier() throws {
    let root = try packageRoot()
    let workflow = try String(
      contentsOf: root.appending(path: ".github/workflows/ci.yml"),
      encoding: .utf8
    )
    let archiveRange = workflow.range(of: "./script/package_release.sh --verify-archive")
    let artifactRange = workflow.range(of: "./script/package_release.sh --verify-artifacts")

    XCTAssertNotNil(archiveRange)
    XCTAssertNotNil(artifactRange)
    XCTAssertLessThan(archiveRange?.lowerBound ?? workflow.endIndex, artifactRange?.lowerBound ?? workflow.startIndex)
    XCTAssertTrue(workflow.contains("uses: actions/checkout@v6"))
  }

  func testReleaseWorkflowVerifiesArtifactsBeforeUploadAndCleansTemporaryKeychain() throws {
    let root = try packageRoot()
    let workflow = try String(
      contentsOf: root.appending(path: ".github/workflows/release.yml"),
      encoding: .utf8
    )
    let verifyRange = workflow.range(of: "name: Verify release artifacts")
    let uploadRange = workflow.range(of: "uses: actions/upload-artifact@v7")

    XCTAssertTrue(workflow.contains("environment: release"))
    XCTAssertTrue(workflow.contains("uses: actions/checkout@v6"))
    XCTAssertTrue(workflow.contains("- self-hosted"))
    XCTAssertTrue(workflow.contains("- macOS"))
    XCTAssertTrue(workflow.contains("- ARM64"))
    XCTAssertTrue(workflow.contains("- jarvis"))
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

  private func makeFakeGitHubCLI(
    environmentSecrets: [String],
    repositorySecrets: [String]
  ) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-gh-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let executable = directory.appending(path: "gh")
    let environmentSecretOutput = environmentSecrets.joined(separator: "\\n")
    let repositorySecretOutput = repositorySecrets.joined(separator: "\\n")
    let script = """
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ "$1" == "api" ]]; then
      endpoint="$2"
      joined="$*"
      if [[ "$endpoint" == "repos/devaryakjha/bonsai/environments/release" ]]; then
        if [[ "$joined" == *required_reviewers* ]]; then
          printf '%s\\n' devaryakjha
        else
          printf '%s\\n' release
        fi
        exit 0
      fi
      if [[ "$endpoint" == "repos/devaryakjha/bonsai/actions/runners" ]]; then
        printf '%s\\n' 'jarvis-bonsai\tonline\tself-hosted,macOS,ARM64,jarvis'
        exit 0
      fi
    fi

    if [[ "$1" == "secret" && "$2" == "list" ]]; then
      joined="$*"
      if [[ "$joined" == *"--env release"* ]]; then
        printf '%b' "\(environmentSecretOutput)"
      else
        printf '%b' "\(repositorySecretOutput)"
      fi
      exit 0
    fi

    printf 'unexpected gh invocation: %s\\n' "$*" >&2
    exit 2
    """
    try script.write(to: executable, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: executable.path(percentEncoded: false)
    )
    return directory
  }
}

private struct ProcessResult {
  var status: Int32
  var output: String
}
