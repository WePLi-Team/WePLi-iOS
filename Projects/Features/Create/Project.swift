import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 3단계 — 만들기 기능 묶음(게시글 작성 · 곡 선택 · 릴레이 만들기 · 명함)

let project = Project(
  name: "WePLiCreateFeatures",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiCreateFeatures",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.createfeatures",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .project(target: "WePLiDesignSystem", path: "../../Core/DesignSystem"),
        .project(target: "WePLiSharedModels", path: "../../Core/SharedModels"),
        .project(target: "WePLiMusicFeatures", path: "../Music"),
      ]
    ),
  ]
)
