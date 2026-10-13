import SwiftUI

@main
struct WePLiApp: App {
  init() {
    WePLiFont.register()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
