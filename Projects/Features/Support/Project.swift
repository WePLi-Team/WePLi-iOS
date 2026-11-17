import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 3단계(시범) — 지원 기능 묶음: 공지 · 앱 정보 · 운영정책 · 이의 신청 · 고객센터 · 문의 내역 · 알림 설정.
// 서로만 참조하고 다른 기능에 의존하지 않는다. 메인 탭 · 시스템 상태 · 계정이 이 모듈을 쓴다.

let project = Project(
  name: "WePLiSupportFeatures",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiSupportFeatures",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.supportfeatures",
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
