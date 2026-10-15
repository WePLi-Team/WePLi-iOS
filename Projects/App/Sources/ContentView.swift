import ComposableArchitecture
import SwiftUI

struct ContentView: View {
  @State private var store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }

  var body: some View {
    AppView(store: self.store)
  }
}
