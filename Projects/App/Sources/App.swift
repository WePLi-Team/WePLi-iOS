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
      ContentView()
        .wepliSystemStatus(self.systemStatus)
    }
  }
}
