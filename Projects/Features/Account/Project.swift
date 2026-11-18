import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 3단계 — 계정 · 프로필 기능 묶음(계정 관리 · 로그인 · 마이 · 내 정보 수정 · 시스템 상태 · 서비스 안내)

let project = Project(
  name: "WePLiAccountFeatures",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiAccountFeatures",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.accountfeatures",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"],
      resources: ["Resources/**"],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .project(target: "WePLiDesignSystem", path: "../../Core/DesignSystem"),
        .project(target: "WePLiSharedModels", path: "../../Core/SharedModels"),
        .project(target: "WePLiSupportFeatures", path: "../Support"),
        .project(target: "WePLiCommunityFeatures", path: "../Community"),
      ]
    ),
  ]
)
