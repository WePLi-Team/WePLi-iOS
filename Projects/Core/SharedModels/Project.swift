import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 2단계 — 여러 기능이 함께 쓰는 값 타입(곡 · 게시글 · 릴레이 · 프로필 · 이의 신청 대상 · 표시 형식).
// Foundation에만 의존한다. 동적 프레임워크로 둬 테스트 번들에 두 번 링크되지 않는다(#207).

let project = Project(
  name: "WePLiSharedModels",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiSharedModels",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.sharedmodels",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"]
    ),
  ]
)
