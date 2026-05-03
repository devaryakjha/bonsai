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
    let draftReleaseScript = try String(
      contentsOf: root.appending(path: "script/create_github_draft_release.sh"),
      encoding: .utf8
    )
    let runnerScript = try String(
      contentsOf: root.appending(path: "script/check_release_runner.sh"),
      encoding: .utf8
    )
    let help = try runPackageRelease(arguments: ["--help"]).output
    let runnerHelp = try runScript("script/check_release_runner.sh", arguments: ["--help"]).output

    XCTAssertTrue(help.contains("--verify-artifacts"), help)
    XCTAssertTrue(help.contains("--github-doctor"), help)
    XCTAssertTrue(help.contains("BONSAI_NOTARY_KEYCHAIN"), help)
    XCTAssertTrue(runnerHelp.contains("--workflow"), runnerHelp)
    XCTAssertTrue(runnerHelp.contains("--workflow-local"), runnerHelp)
    XCTAssertTrue(script.contains("verify_release_artifacts()"))
    XCTAssertTrue(script.contains("github_release_doctor()"))
    XCTAssertTrue(script.contains("print_github_release_remediation()"))
    XCTAssertTrue(script.contains("manifest archiveSHA256 mismatch"))
    XCTAssertTrue(script.contains("plutil -extract archiveSHA256 raw"))
    XCTAssertTrue(runnerScript.contains("Release workflow runner: ready"), runnerScript)
    XCTAssertTrue(runnerScript.contains("notarytool: available"), runnerScript)
    XCTAssertTrue(runnerScript.contains("Developer ID signing smoke: valid"), runnerScript)
    XCTAssertTrue(draftReleaseScript.contains("Draft GitHub release created for"), draftReleaseScript)
    XCTAssertTrue(draftReleaseScript.contains("cleanup_release()"), draftReleaseScript)
    XCTAssertTrue(draftReleaseScript.contains("$API_BASE/releases/tags/$RELEASE_TAG"), draftReleaseScript)
    XCTAssertTrue(draftReleaseScript.contains("$UPLOADS_BASE/releases/$release_id/assets"), draftReleaseScript)
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
    XCTAssertTrue(result.output.contains("Next steps:"), result.output)
    XCTAssertTrue(result.output.contains("./script/configure_github_release_secrets.sh --print-template"), result.output)
    XCTAssertTrue(result.output.contains("./script/configure_github_release_secrets.sh --dry-run"), result.output)
    XCTAssertTrue(result.output.contains("gh workflow run Release --repo devaryakjha/bonsai --ref main -f dry_run=true"), result.output)
    XCTAssertTrue(result.output.contains("gh workflow run Release --repo devaryakjha/bonsai --ref main -f dry_run=false"), result.output)
    XCTAssertTrue(result.output.contains("GitHub release configuration: not ready"), result.output)
    XCTAssertFalse(result.output.contains("Packaged "), result.output)
  }

  func testGitHubDoctorOmitsRemediationWhenReady() throws {
    let fakeBin = try makeFakeGitHubCLI(
      environmentSecrets: [
        "BONSAI_CODESIGN_IDENTITY",
        "BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64",
        "BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD",
        "BONSAI_NOTARY_APPLE_ID",
        "BONSAI_NOTARY_APP_PASSWORD",
        "BONSAI_NOTARY_TEAM_ID"
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

    XCTAssertEqual(result.status, 0, result.output)
    XCTAssertTrue(result.output.contains("GitHub release configuration: ready"), result.output)
    XCTAssertFalse(result.output.contains("Next steps:"), result.output)
    XCTAssertFalse(result.output.contains("--print-template"), result.output)
  }

  func testGitHubSecretConfiguratorDryRunDoesNotUploadOrPrintSecrets() throws {
    let fakeBin = try makeFakeGitHubSecretConfiguratorCLI(
      log: nil,
      failOnSecretSet: true
    )
    let certificate = try makeTemporaryCertificate(contents: "certificate-private-bytes")
    let path = [
      fakeBin.path(percentEncoded: false),
      ProcessInfo.processInfo.environment["PATH"] ?? ""
    ].joined(separator: ":")
    let result = try runScript(
      "script/configure_github_release_secrets.sh",
      arguments: ["--dry-run"],
      environment: releaseSecretEnvironment(path: path, certificate: certificate)
    )

    XCTAssertEqual(result.status, 0, result.output)
    XCTAssertTrue(result.output.contains("Bonsai GitHub release secret configurator"), result.output)
    XCTAssertTrue(result.output.contains("release environment: available"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64: ready from certificate file"), result.output)
    XCTAssertTrue(result.output.contains("Developer ID certificate: importable"), result.output)
    XCTAssertTrue(result.output.contains("Developer ID certificate identity: matches configured identity"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_NOTARY_APP_PASSWORD: ready"), result.output)
    XCTAssertTrue(result.output.contains("Dry run complete; no GitHub secrets were changed"), result.output)
    XCTAssertFalse(result.output.contains("certificate-private-bytes"), result.output)
    XCTAssertFalse(result.output.contains("notary-password-secret"), result.output)
  }

  func testGitHubSecretConfiguratorPrintsNoSecretTemplateWithoutGh() throws {
    let fakeBin = try makeFakeGitHubSecretConfiguratorCLI(
      log: nil,
      failOnSecretSet: true
    )
    let result = try runScript(
      "script/configure_github_release_secrets.sh",
      arguments: ["--print-template"],
      environment: [
        "PATH": [
          fakeBin.path(percentEncoded: false),
          "/usr/bin",
          "/bin",
          "/usr/sbin",
          "/sbin"
        ].joined(separator: ":")
      ]
    )

    XCTAssertEqual(result.status, 0, result.output)
    XCTAssertTrue(result.output.contains("Do not commit this output"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_CODESIGN_IDENTITY"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_DEVELOPER_ID_CERTIFICATE_PATH"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_NOTARY_APPLE_ID"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_NOTARY_APP_PASSWORD"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_NOTARY_TEAM_ID"), result.output)
    XCTAssertTrue(result.output.contains("./script/configure_github_release_secrets.sh --dry-run"), result.output)
    XCTAssertTrue(result.output.contains("./script/package_release.sh --github-doctor"), result.output)
    XCTAssertFalse(result.output.contains("GitHub CLI: missing"), result.output)
  }

  func testGitHubSecretConfiguratorUploadsOnlyEnvironmentSecretsWithMockedGh() throws {
    let log = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-gh-secret-log-\(UUID().uuidString)")
    let fakeBin = try makeFakeGitHubSecretConfiguratorCLI(
      log: log,
      failOnSecretSet: false
    )
    let certificate = try makeTemporaryCertificate(contents: "certificate-private-bytes")
    let path = [
      fakeBin.path(percentEncoded: false),
      ProcessInfo.processInfo.environment["PATH"] ?? ""
    ].joined(separator: ":")
    let result = try runScript(
      "script/configure_github_release_secrets.sh",
      environment: releaseSecretEnvironment(path: path, certificate: certificate)
    )

    XCTAssertEqual(result.status, 0, result.output)
    XCTAssertTrue(result.output.contains("Developer ID certificate: importable"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_CODESIGN_IDENTITY: uploaded to release"), result.output)
    XCTAssertTrue(result.output.contains("BONSAI_NOTARY_TEAM_ID: uploaded to release"), result.output)
    XCTAssertTrue(result.output.contains("GitHub release configuration: ready"), result.output)

    let logText = try String(contentsOf: log, encoding: .utf8)
    let uploadedSecrets = logText
      .split(separator: "\n")
      .map(String.init)
      .filter { $0.hasPrefix("set|") }

    XCTAssertEqual(uploadedSecrets.count, 6, logText)
    XCTAssertTrue(uploadedSecrets.allSatisfy { $0.contains("--env release") }, logText)
    XCTAssertTrue(uploadedSecrets.allSatisfy { $0.contains("--repo devaryakjha/bonsai") }, logText)
    XCTAssertTrue(logText.contains("set|BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64|"), logText)
    XCTAssertFalse(logText.contains("certificate-private-bytes"), logText)
    XCTAssertFalse(logText.contains("notary-password-secret"), logText)
  }

  func testGitHubSecretConfiguratorRejectsCertificateWithoutConfiguredIdentity() throws {
    let fakeBin = try makeFakeGitHubSecretConfiguratorCLI(
      log: nil,
      failOnSecretSet: true,
      certificateIdentity: "Developer ID Application: Other, Inc. (OTHERID)"
    )
    let certificate = try makeTemporaryCertificate(contents: "certificate-private-bytes")
    let path = [
      fakeBin.path(percentEncoded: false),
      ProcessInfo.processInfo.environment["PATH"] ?? ""
    ].joined(separator: ":")
    let result = try runScript(
      "script/configure_github_release_secrets.sh",
      arguments: ["--dry-run"],
      environment: releaseSecretEnvironment(path: path, certificate: certificate)
    )

    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(
      result.output.contains("Developer ID certificate identity: configured identity not found in .p12"),
      result.output
    )
    XCTAssertTrue(result.output.contains("GitHub release secrets: not ready"), result.output)
    XCTAssertFalse(result.output.contains("certificate-private-bytes"), result.output)
    XCTAssertFalse(result.output.contains("notary-password-secret"), result.output)
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
    XCTAssertTrue(workflow.contains("script/check_release_runner.sh"))
    XCTAssertTrue(workflow.contains("script/configure_github_release_secrets.sh"))
    XCTAssertTrue(workflow.contains("script/create_github_draft_release.sh"))
  }

  func testReleaseWorkflowVerifiesArtifactsBeforeUploadAndCleansTemporaryKeychain() throws {
    let root = try packageRoot()
    let workflow = try String(
      contentsOf: root.appending(path: ".github/workflows/release.yml"),
      encoding: .utf8
    )
    let dryRunJobRange = try XCTUnwrap(workflow.range(of: "dry-run:"))
    let notarizeJobRange = try XCTUnwrap(workflow.range(of: "notarize:"))
    let dryRunJob = String(workflow[dryRunJobRange.lowerBound..<notarizeJobRange.lowerBound])
    let notarizeJob = String(workflow[notarizeJobRange.lowerBound..<workflow.endIndex])
    let dryRunVerifyRange = dryRunJob.range(of: "name: Verify release artifacts")
    let dryRunUploadRange = dryRunJob.range(of: "uses: actions/upload-artifact@v7")
    let notarizeVerifyRange = notarizeJob.range(of: "name: Verify release artifacts")
    let notarizeUploadRange = notarizeJob.range(of: "uses: actions/upload-artifact@v7")
    let releaseRange = notarizeJob.range(of: "./script/create_github_draft_release.sh")

    XCTAssertTrue(workflow.contains("contents: write"))
    XCTAssertTrue(workflow.contains("dry_run:"), workflow)
    XCTAssertTrue(workflow.contains("default: true"), workflow)
    XCTAssertTrue(workflow.contains("uses: actions/checkout@v6"))
    XCTAssertTrue(workflow.contains("bash -n script/check_release_runner.sh"))
    XCTAssertTrue(workflow.contains("bash -n script/configure_github_release_secrets.sh"))
    XCTAssertTrue(workflow.contains("dist/release/Bonsai.zip"))
    XCTAssertTrue(workflow.contains("dist/release/Bonsai.release.plist"))

    XCTAssertTrue(dryRunJob.contains("if: ${{ inputs.dry_run == true }}"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("- self-hosted"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("- macOS"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("- ARM64"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("- jarvis"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("BONSAI_RELEASE_DRY_RUN=true"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("./script/package_release.sh --verify-archive"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("./script/package_release.sh --verify-artifacts"), dryRunJob)
    XCTAssertTrue(dryRunJob.contains("Upload dry-run artifact"), dryRunJob)
    XCTAssertFalse(dryRunJob.contains("environment: release"), dryRunJob)
    XCTAssertFalse(dryRunJob.contains("${{ secrets."), dryRunJob)
    XCTAssertFalse(dryRunJob.contains("./script/package_release.sh --notarize"), dryRunJob)
    XCTAssertNotNil(dryRunVerifyRange)
    XCTAssertNotNil(dryRunUploadRange)
    XCTAssertLessThan(dryRunVerifyRange?.lowerBound ?? dryRunJob.endIndex, dryRunUploadRange?.lowerBound ?? dryRunJob.startIndex)

    XCTAssertTrue(notarizeJob.contains("if: ${{ inputs.dry_run != true }}"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("environment: release"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("BONSAI_RELEASE_DRY_RUN=false"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("BONSAI_NOTARY_KEYCHAIN=$RUNNER_TEMP/bonsai-signing.keychain-db"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("security import \"$developer_id_g2_path\""), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("./script/package_release.sh --notarize"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("./script/package_release.sh --verify-artifacts"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("GH_TOKEN: ${{ github.token }}"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("run: ./script/create_github_draft_release.sh"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("if: always()"), notarizeJob)
    XCTAssertTrue(notarizeJob.contains("security delete-keychain \"$BONSAI_NOTARY_KEYCHAIN\""), notarizeJob)
    XCTAssertFalse(notarizeJob.contains("./script/package_release.sh --verify-archive"), notarizeJob)
    XCTAssertNotNil(notarizeVerifyRange)
    XCTAssertNotNil(notarizeUploadRange)
    XCTAssertNotNil(releaseRange)
    XCTAssertLessThan(notarizeVerifyRange?.lowerBound ?? notarizeJob.endIndex, notarizeUploadRange?.lowerBound ?? notarizeJob.startIndex)
    XCTAssertLessThan(notarizeUploadRange?.lowerBound ?? notarizeJob.endIndex, releaseRange?.lowerBound ?? notarizeJob.startIndex)

    XCTAssertTrue(workflow.contains("curl --version | sed -n '1p'"))
    XCTAssertTrue(workflow.contains("jq --version"))
    XCTAssertTrue(workflow.contains("bash -n script/create_github_draft_release.sh"))
    XCTAssertFalse(workflow.contains("gh release create"))
  }

  func testDraftReleaseScriptCreatesDraftAndUploadsAssetsWithMockedCurl() throws {
    try requireExecutable("jq")
    let root = try packageRoot()
    let fixture = try makeDraftReleaseFixture(failManifestUpload: false)
    let result = try runScript(
      "script/create_github_draft_release.sh",
      environment: draftReleaseEnvironment(root: root, fixture: fixture)
    )

    XCTAssertEqual(result.status, 0, result.output)
    XCTAssertTrue(result.output.contains("Draft GitHub release created for v9.8.7"), result.output)

    let logText = try String(contentsOf: fixture.log, encoding: .utf8)
    XCTAssertTrue(logText.contains("GET|https://api.github.com/repos/devaryakjha/bonsai/releases/tags/v9.8.7"), logText)
    XCTAssertTrue(logText.contains("GET|https://api.github.com/repos/devaryakjha/bonsai/git/ref/tags/v9.8.7"), logText)
    XCTAssertTrue(logText.contains("POST|https://api.github.com/repos/devaryakjha/bonsai/releases"), logText)
    XCTAssertTrue(logText.contains("POST|https://uploads.github.com/repos/devaryakjha/bonsai/releases/42/assets?name=Bonsai.zip"), logText)
    XCTAssertTrue(logText.contains("POST|https://uploads.github.com/repos/devaryakjha/bonsai/releases/42/assets?name=Bonsai.release.plist"), logText)
    XCTAssertFalse(logText.contains("DELETE|"), logText)
  }

  func testDraftReleaseScriptCleansPartialReleaseAndGeneratedTagOnAssetFailure() throws {
    try requireExecutable("jq")
    let root = try packageRoot()
    let fixture = try makeDraftReleaseFixture(failManifestUpload: true)
    let result = try runScript(
      "script/create_github_draft_release.sh",
      environment: draftReleaseEnvironment(root: root, fixture: fixture)
    )

    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(
      result.output.contains("GitHub release asset upload failed for Bonsai.release.plist"),
      result.output
    )

    let logText = try String(contentsOf: fixture.log, encoding: .utf8)
    XCTAssertTrue(logText.contains("DELETE|https://api.github.com/repos/devaryakjha/bonsai/releases/42"), logText)
    XCTAssertTrue(logText.contains("DELETE|https://api.github.com/repos/devaryakjha/bonsai/git/refs/tags/v9.8.7"), logText)
  }

  func testDraftReleaseScriptKeepsPreexistingTagOnAssetFailure() throws {
    try requireExecutable("jq")
    let root = try packageRoot()
    let fixture = try makeDraftReleaseFixture(failManifestUpload: true, tagExists: true)
    let result = try runScript(
      "script/create_github_draft_release.sh",
      environment: draftReleaseEnvironment(root: root, fixture: fixture)
    )

    XCTAssertNotEqual(result.status, 0)
    XCTAssertTrue(
      result.output.contains("GitHub release asset upload failed for Bonsai.release.plist"),
      result.output
    )

    let logText = try String(contentsOf: fixture.log, encoding: .utf8)
    XCTAssertTrue(logText.contains("DELETE|https://api.github.com/repos/devaryakjha/bonsai/releases/42"), logText)
    XCTAssertFalse(logText.contains("DELETE|https://api.github.com/repos/devaryakjha/bonsai/git/refs/tags/v9.8.7"), logText)
  }

  private func runPackageRelease(
    arguments: [String],
    environment overrides: [String: String] = [:]
  ) throws -> ProcessResult {
    try runScript("script/package_release.sh", arguments: arguments, environment: overrides)
  }

  private func runScript(
    _ relativePath: String,
    arguments: [String] = [],
    environment overrides: [String: String] = [:]
  ) throws -> ProcessResult {
    let root = try packageRoot()
    let process = Process()
    let outputPipe = Pipe()
    let script = root.appending(path: relativePath).path(percentEncoded: false)

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

  private func requireExecutable(_ name: String) throws {
    let process = Process()
    process.executableURL = URL(filePath: "/bin/bash")
    process.arguments = ["-lc", "command -v \(name) >/dev/null"]
    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
      throw XCTSkip("\(name) is not available")
    }
  }

  private func releaseSecretEnvironment(path: String, certificate: URL) -> [String: String] {
    [
      "PATH": path,
      "BONSAI_CODESIGN_IDENTITY": "Developer ID Application: Example, Inc. (TEAMID)",
      "BONSAI_DEVELOPER_ID_CERTIFICATE_PATH": certificate.path(percentEncoded: false),
      "BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD": "p12-password-secret",
      "BONSAI_NOTARY_APPLE_ID": "developer@example.com",
      "BONSAI_NOTARY_APP_PASSWORD": "notary-password-secret",
      "BONSAI_NOTARY_TEAM_ID": "TEAMID"
    ]
  }

  private func makeTemporaryCertificate(contents: String) throws -> URL {
    let certificate = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-developer-id-\(UUID().uuidString).p12")
    try contents.write(to: certificate, atomically: true, encoding: .utf8)
    return certificate
  }

  private func draftReleaseEnvironment(root: URL, fixture: DraftReleaseFixture) -> [String: String] {
    let path = [
      fixture.fakeBin.path(percentEncoded: false),
      ProcessInfo.processInfo.environment["PATH"] ?? ""
    ].joined(separator: ":")
    return [
      "PATH": path,
      "GH_TOKEN": "test-token",
      "GITHUB_REPOSITORY": "devaryakjha/bonsai",
      "GITHUB_SHA": "0123456789abcdef",
      "BONSAI_VERSION": "9.8.7",
      "BONSAI_BUILD_NUMBER": "123",
      "BONSAI_RELEASE_ARCHIVE": fixture.archive.path(percentEncoded: false),
      "BONSAI_RELEASE_MANIFEST": fixture.manifest.path(percentEncoded: false),
      "RUNNER_TEMP": fixture.runnerTemp.path(percentEncoded: false)
    ]
  }

  private func makeDraftReleaseFixture(
    failManifestUpload: Bool,
    tagExists: Bool = false
  ) throws -> DraftReleaseFixture {
    let directory = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-draft-release-\(UUID().uuidString)", directoryHint: .isDirectory)
    let fakeBin = directory.appending(path: "bin", directoryHint: .isDirectory)
    let runnerTemp = directory.appending(path: "runner", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: fakeBin, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: runnerTemp, withIntermediateDirectories: true)

    let archive = directory.appending(path: "Bonsai.zip")
    let manifest = directory.appending(path: "Bonsai.release.plist")
    let log = directory.appending(path: "curl.log")
    try "zip-bytes".write(to: archive, atomically: true, encoding: .utf8)
    try "manifest-bytes".write(to: manifest, atomically: true, encoding: .utf8)

    let curl = fakeBin.appending(path: "curl")
    let manifestStatus = failManifestUpload ? "500" : "201"
    let manifestBody = failManifestUpload ? #"{"message":"upload failed"}"# : #"{"name":"Bonsai.release.plist"}"#
    let tagLookupStatus = tagExists ? "200" : "404"
    let tagLookupBody = tagExists ? #"{"ref":"refs/tags/v9.8.7"}"# : #"{"message":"Not Found"}"#
    let script = """
    #!/usr/bin/env bash
    set -euo pipefail

    log="\(log.path(percentEncoded: false))"
    method="GET"
    output="/dev/null"
    url=""

    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -X)
          method="$2"
          shift 2
          ;;
        -o)
          output="$2"
          shift 2
          ;;
        -w)
          shift 2
          ;;
        -H)
          shift 2
          ;;
        --data-binary)
          shift 2
          ;;
        -sS)
          shift
          ;;
        *)
          url="$1"
          shift
          ;;
      esac
    done

    printf '%s|%s\\n' "$method" "$url" >> "$log"

    status="500"
    body='{"message":"unexpected"}'
    case "$method|$url" in
      "GET|https://api.github.com/repos/devaryakjha/bonsai/releases/tags/v9.8.7")
        status="404"
        body='{"message":"Not Found"}'
        ;;
      "GET|https://api.github.com/repos/devaryakjha/bonsai/git/ref/tags/v9.8.7")
        status="\(tagLookupStatus)"
        body='\(tagLookupBody)'
        ;;
      "POST|https://api.github.com/repos/devaryakjha/bonsai/releases")
        status="201"
        body='{"id":42}'
        ;;
      "POST|https://uploads.github.com/repos/devaryakjha/bonsai/releases/42/assets?name=Bonsai.zip")
        status="201"
        body='{"name":"Bonsai.zip"}'
        ;;
      "POST|https://uploads.github.com/repos/devaryakjha/bonsai/releases/42/assets?name=Bonsai.release.plist")
        status="\(manifestStatus)"
        body='\(manifestBody)'
        ;;
      "DELETE|https://api.github.com/repos/devaryakjha/bonsai/releases/42")
        status="204"
        body='{}'
        ;;
      "DELETE|https://api.github.com/repos/devaryakjha/bonsai/git/refs/tags/v9.8.7")
        status="204"
        body='{}'
        ;;
    esac

    printf '%s' "$body" > "$output"
    printf '%s' "$status"
    """
    try script.write(to: curl, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: curl.path(percentEncoded: false)
    )

    return DraftReleaseFixture(
      fakeBin: fakeBin,
      runnerTemp: runnerTemp,
      archive: archive,
      manifest: manifest,
      log: log
    )
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

  private func makeFakeGitHubSecretConfiguratorCLI(
    log: URL?,
    failOnSecretSet: Bool,
    certificateIdentity: String = "Developer ID Application: Example, Inc. (TEAMID)"
  ) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appending(path: "bonsai-gh-secrets-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let executable = directory.appending(path: "gh")
    let logPath = log?.path(percentEncoded: false) ?? "/dev/null"
    let secretSetExit = failOnSecretSet ? "exit 9" : "exit 0"
    let script = """
    #!/usr/bin/env bash
    set -euo pipefail
    log="\(logPath)"

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

    if [[ "$1" == "secret" && "$2" == "set" ]]; then
      value="$(cat)"
      printf 'set|%s|%s\\n' "$3" "$*" >> "$log"
      \(secretSetExit)
    fi

    if [[ "$1" == "secret" && "$2" == "list" ]]; then
      joined="$*"
      if [[ "$joined" == *"--env release"* ]]; then
        printf '%s\\n' \\
          BONSAI_CODESIGN_IDENTITY \\
          BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64 \\
          BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD \\
          BONSAI_NOTARY_APPLE_ID \\
          BONSAI_NOTARY_APP_PASSWORD \\
          BONSAI_NOTARY_TEAM_ID
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
    let security = directory.appending(path: "security")
    let securityScript = """
    #!/usr/bin/env bash
    set -euo pipefail

    case "$1" in
      create-keychain)
        last=""
        for argument in "$@"; do
          last="$argument"
        done
        : > "$last"
        ;;
      unlock-keychain)
        ;;
      import)
        ;;
      find-identity)
        printf '%s\\n' '  1) ABCDEF1234567890 "\(certificateIdentity)"'
        ;;
      delete-keychain)
        ;;
      *)
        printf 'unexpected security invocation: %s\\n' "$*" >&2
        exit 2
        ;;
    esac
    """
    try securityScript.write(to: security, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: security.path(percentEncoded: false)
    )
    return directory
  }
}

private struct ProcessResult {
  var status: Int32
  var output: String
}

private struct DraftReleaseFixture {
  var fakeBin: URL
  var runnerTemp: URL
  var archive: URL
  var manifest: URL
  var log: URL
}
