@testable import WePLi
import XCTest

// REQ-003 · UI-10f — 빈 상태 문구 · 스켈레톤 수치가 원본과 같은지 지킨다.

final class EmptyStateTests: XCTestCase {
  func testPresets_useDesignCopy() {
    let feed = WePLiEmptyState.feed {}
    XCTAssertEqual(feed.title, "아직 게시글이 없어요")
    XCTAssertEqual(feed.message, "좋아하는 노래 한 곡으로 첫 글을 써보세요.")
    XCTAssertEqual(feed.actionTitle, "글쓰기")

    let library = WePLiEmptyState.library {}
    XCTAssertEqual(library.title, "보관함이 비어 있어요")
    XCTAssertEqual(library.actionTitle, "홈에서 둘러보기")

    let search = WePLiEmptyState.searchNoResult(query: "ㅁㄴㅇㄹ") {}
    XCTAssertEqual(search.title, "‘ㅁㄴㅇㄹ’ 검색 결과가 없어요")
    XCTAssertEqual(search.actionTitle, "둘러보기로 가기")

    let notifications = WePLiEmptyState.notifications {}
    XCTAssertEqual(notifications.title, "새 알림이 없어요")
    XCTAssertEqual(notifications.actionTitle, "릴레이 보러 가기")
  }

  func testEveryPreset_hasOneAction() {
    let presets = [
      WePLiEmptyState.feed {},
      WePLiEmptyState.library {},
      WePLiEmptyState.searchNoResult(query: "a") {},
      WePLiEmptyState.notifications {},
    ]
    for preset in presets {
      XCTAssertNotNil(preset.actionTitle, preset.title)
      XCTAssertNotNil(preset.action, preset.title)
    }
  }

  func testMetrics_matchDesign() {
    XCTAssertEqual(WePLiEmptyState.Metric.iconCircle, 72)
    XCTAssertEqual(WePLiEmptyState.Metric.buttonHeight, 44)
    XCTAssertEqual(WePLiSkeleton.dimmedOpacity, 0.45)
    XCTAssertEqual(WePLiSkeleton.pulseDuration, 0.9)
  }
}
