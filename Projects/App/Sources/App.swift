import ComposableArchitecture
import SwiftUI

@main
struct WePLiApp: App {
  /// 시스템 상태(UI-7d) — 앱 시작 때 서버 설정을 받는다(DEC-014)
  private let systemStatus = Store(initialState: SystemStatusFeature.State()) {
    SystemStatusFeature()
  }

  init() {
    WePLiFont.register()
  }

  var body: some Scene {
    WindowGroup {
      // 단위 테스트의 호스트 앱으로 뜰 때는 화면을 띄우지 않는다 — 시스템 상태가 테스트용 의존성을 불러 다른 테스트를 실패시킨다
      if !isTesting {
        ContentView()
          .wepliSystemStatus(self.systemStatus)
      }
    }
  }
}
