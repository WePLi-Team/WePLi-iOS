import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 3단계 — 홈 기능 묶음(홈 · 실시간 트렌드 · 오늘의 곡 · 완성 플리 · 내보내기 · 음악 서비스 · 듣는 중 공유)

let project = Project(
  name: "WePLiHomeFeatures",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiHomeFeatures",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.homefeatures",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .project(target: "WePLiDesignSystem", path: "../../Core/DesignSystem"),
        .project(target: "WePLiSharedModels", path: "../../Core/SharedModels"),
        .project(target: "WePLiRelayFeatures", path: "../Relay"),
        .project(target: "WePLiCreateFeatures", path: "../Create"),
      ]
    ),
  ]
)
