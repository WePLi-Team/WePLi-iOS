import ComposableArchitecture
import SwiftUI

struct ContentView: View {
  var body: some View {
    LoginView(
      store: Store(initialState: LoginFeature.State()) {
        LoginFeature()
      }
    )
  }
}
