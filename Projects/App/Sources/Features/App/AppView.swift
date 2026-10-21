import ComposableArchitecture
import SwiftUI

struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    WithPerceptionTracking {
      switch self.store.state {
      case .login:
        if let loginStore = self.store.scope(state: \.login, action: \.login) {
          LoginView(store: loginStore)
        }
      case .mainTab:
        if let mainTabStore = self.store.scope(state: \.mainTab, action: \.mainTab) {
          MainTabView(store: mainTabStore)
        }
      }
    }
  }
}

#Preview {
  AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}
