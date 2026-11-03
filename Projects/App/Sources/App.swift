import ComposableArchitecture
import SwiftUI

#if !DEBUG
  // 출시 빌드를 만들 때 알린다 — 백엔드가 정해지지 않아 Client의 liveValue가 목업(mockValue)이고,
  // 로그인(AuthClient)은 1초 뒤 무조건 성공한다(#14). 실제 연결 뒤 이 경고를 지운다.
  #warning("목업 Client · 가짜 로그인으로 Release 빌드 중 — 출시 전 실제 API · 로그인 연결(#14)")
#endif

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
      // 테스트 호스트로 뜰 때는 앱 화면을 띄우지 않는다 — 시작 effect(시스템 상태 설정 받기 등)가
      // 테스트용 의존성을 호출해, 그 순간 실행 중인 테스트의 실패로 기록된다(#209)
      if isTesting {
        EmptyView()
      } else {
        ContentView()
          .wepliSystemStatus(self.systemStatus)
      }
    }
  }
}
