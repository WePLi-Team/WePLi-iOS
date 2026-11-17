import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 3단계 — 커뮤니티 기능 묶음: 피드 · 친구 피드 · 내 게시글 · 게시글 상세 · 팔로우 목록 · 친구 프로필 · 취향 궁합 · 알림.

let project = Project(
  name: "WePLiCommunityFeatures",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiCommunityFeatures",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.communityfeatures",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      // 잠금화면 위젯 데이터(앱 · 위젯 공유, DEC-015) — 앱에서는 친구 피드가 쓴다. 위젯은 같은 파일을 직접 컴파일한다
      sources: ["Sources/**", "../../App/Shared/Sources/**"],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .project(target: "WePLiDesignSystem", path: "../../Core/DesignSystem"),
        .project(target: "WePLiSharedModels", path: "../../Core/SharedModels"),
        .project(target: "WePLiSupportFeatures", path: "../Support"),
      ]
    ),
  ]
)
