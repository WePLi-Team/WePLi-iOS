import ComposableArchitecture
import SwiftUI

struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    WithPerceptionTracking {
      if store.isLoggedIn {
        MainView(
          store: store.scope(state: \.main, action: \.main)
        )
      } else {
        LoginView(
          store: store.scope(state: \.login, action: \.login)
        )
      }
    }
  }
}

#Preview("Logged Out") {
  AppView(
    store: Store(initialState: AppFeature.State()) {
      AppFeature()
    }
  )
}

#Preview("Logged In") {
  AppView(
    store: Store(initialState: AppFeature.State(isLoggedIn: true)) {
      AppFeature()
    }
  )
}
