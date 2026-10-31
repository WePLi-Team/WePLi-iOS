import SwiftUI

// 남은 시간처럼 매초 바뀌는 글자 — 화면 전체가 아니라 이 뷰만 정해진 간격으로 다시 그린다(TimelineView).
// 리듀서가 1초 타이머로 `now`를 바꾸면 그 값을 읽는 화면 전체가 매초 다시 계산된다.

struct WePLiTicking<Content: View>: View {
  var interval: TimeInterval = 1
  @ViewBuilder let content: (Date) -> Content

  var body: some View {
    TimelineView(.periodic(from: .now, by: self.interval)) { context in
      self.content(context.date)
    }
  }
}
