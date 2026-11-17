import ProjectDescription
import ProjectDescriptionHelpers

// DEC-033 · 모듈 분리 1단계 — 디자인 토큰(WePLiColor · WePLiFont · WePLiGradient) · 크롬 · 공통 컴포넌트 · Pretendard 폰트.
// SwiftUI에만 의존한다. 동적 프레임워크로 둬 테스트 번들에 두 번 링크되지 않는다(#207과 같은 이유).

let project = Project(
  name: "WePLiDesignSystem",
  options: .options(defaultKnownRegions: ["Base", "ko"], developmentRegion: "ko"),
  settings: .settings(base: SharedSettings.base.base),
  targets: [
    .target(
      name: "WePLiDesignSystem",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.example.wepli.designsystem",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"],
      resources: ["Resources/**"]
    ),
  ]
)
