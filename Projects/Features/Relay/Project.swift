import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 3단계 — 릴레이 기능 묶음: 목록 · 상세 · 카드 투표 · 곡 월드컵 · 바통 · 1위 예측 · 내 추천 순위 · 시즌 랭킹.

let project = Project(
  name: "WePLiRelayFeatures",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiRelayFeatures",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.relayfeatures",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .project(target: "WePLiDesignSystem", path: "../../Core/DesignSystem"),
        .project(target: "WePLiSharedModels", path: "../../Core/SharedModels"),
      ]
    ),
  ]
)
