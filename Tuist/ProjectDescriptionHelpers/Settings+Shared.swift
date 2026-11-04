import ProjectDescription

public enum SharedSettings {
  public static let base: Settings = .settings(
    base: [
      "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
      "SWIFT_VERSION": "5.10",
      // 한국어 전용 앱 — 빌드할 때 문구를 Localizable.xcstrings로 자동 추출하지 않는다(#242)
      "SWIFT_EMIT_LOC_STRINGS": "NO",
    ],
    configurations: [
      .debug(name: "Debug"),
      .release(name: "Release"),
    ]
  )
}
