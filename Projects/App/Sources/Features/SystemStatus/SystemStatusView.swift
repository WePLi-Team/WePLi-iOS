import ComposableArchitecture
import SwiftUI

// REQ-112 · UI-7d · DEC-014 — 앱 전체를 감싸는 시스템 상태. 막는 상태(강제 업데이트 · 점검 · 오프라인)는 위를 덮고,
// 이용 제한은 닫을 수 있는 시트, 이벤트는 아래 팝업으로 띄운다.

private struct SystemStatusModifier: ViewModifier {
  @Perception.Bindable var store: StoreOf<SystemStatusFeature>

  func body(content: Content) -> some View {
    WithPerceptionTracking {
      content
        .overlay { self.overlay() }
        .animation(.easeInOut(duration: 0.25), value: self.store.status)
        .sheet(isPresented: Binding(
          get: { self.restriction != nil },
          set: {
            if !$0 {
              self.store.send(.restrictionClosed)
            }
          }
        )) {
          if let restriction = self.restriction {
            RestrictionSheet(restriction: restriction) { self.store.send(.restrictionClosed) }
              .wepliSheetStyle(detents: [.large])
          }
        }
        .task { self.store.send(.launched) }
    }
  }

  private var restriction: CommunityRestriction? {
    if case let .restricted(restriction) = self.store.status {
      return restriction
    }
    return nil
  }

  @ViewBuilder
  private func overlay() -> some View {
    switch self.store.status {
    case let .forceUpdate(current, update):
      ForceUpdateScreen(current: current, update: update) { self.store.send(.updateTapped) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WePLiColor.background.ignoresSafeArea())
    case let .maintenance(maintenance):
      MaintenanceScreen(maintenance: maintenance, now: self.store.now)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WePLiColor.background.ignoresSafeArea())
    case .offline:
      OfflineOverlay(retryCount: self.store.retryCount) { self.store.send(.retryTapped) }
    case let .event(event):
      EventPopup(
        event: event,
        onHideToday: { self.store.send(.eventHiddenToday) },
        onClose: { self.store.send(.eventClosed) }
      )
    case .restricted, nil:
      EmptyView()
    }
  }
}

extension View {
  /// 앱 맨 바깥에 붙인다(App.swift)
  func wepliSystemStatus(_ store: StoreOf<SystemStatusFeature>) -> some View {
    self.modifier(SystemStatusModifier(store: store))
  }
}
