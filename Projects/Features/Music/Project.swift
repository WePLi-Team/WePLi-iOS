import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 3단계 — 음악 기능 묶음(곡 상세 · 아티스트 · 플리 상세 · 보관함 · 내 플리 · 플레이어 · 곡 메뉴 · 곡 공유 · 검색)

let project = Project(
  name: "WePLiMusicFeatures",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiMusicFeatures",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.musicfeatures",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .project(target: "WePLiDesignSystem", path: "../../Core/DesignSystem"),
        .project(target: "WePLiSharedModels", path: "../../Core/SharedModels"),
        .project(target: "WePLiAccountFeatures", path: "../Account"),
      ]
    ),
  ]
)
