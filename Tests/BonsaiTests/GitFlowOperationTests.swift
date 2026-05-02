import XCTest
@testable import Bonsai

final class GitFlowOperationTests: XCTestCase {
  func testOperationKindMappingCoversStartAndFinishActions() {
    XCTAssertEqual(GitFlowStartKind.feature.operationKind(action: .start), .gitFlowFeatureStart)
    XCTAssertEqual(GitFlowStartKind.release.operationKind(action: .start), .gitFlowReleaseStart)
    XCTAssertEqual(GitFlowStartKind.hotfix.operationKind(action: .start), .gitFlowHotfixStart)
    XCTAssertEqual(GitFlowStartKind.feature.operationKind(action: .finish), .gitFlowFeatureFinish)
    XCTAssertEqual(GitFlowStartKind.release.operationKind(action: .finish), .gitFlowReleaseFinish)
    XCTAssertEqual(GitFlowStartKind.hotfix.operationKind(action: .finish), .gitFlowHotfixFinish)
  }
}
