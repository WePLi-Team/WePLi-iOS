// swift-tools-version: 6.0
import PackageDescription

#if TUIST
  import ProjectDescription
  import ProjectDescriptionHelpers

  /// TCA와 그 의존성(Point-Free · swift-collections)은 동적 프레임워크로 링크한다.
  /// 정적이면 테스트 번들이 TestStore 등을 링크하면서 TCA · Sharing 코드를 한 벌 더 넣어
  /// 클래스 · 전역 상태가 앱과 테스트에 두 벌이 된다(#207).
  /// swift-sharing(Sharing · Sharing1 · Sharing2)은 정적으로 둔다 — iOS 비공개 시스템 프레임워크
  /// Sharing.framework와 이름이 겹쳐, 동적이면 Xcode 실행 · 테스트(DYLD_FRAMEWORK_PATH)에서 시스템
  /// LocalStatusKit이 이것을 잘못 로드해 시작하자마자 크래시한다. ComposableArchitecture 안에 한 벌만 들어간다
  let packageSettings = PackageSettings(
    productTypes: [
      "ComposableArchitecture": .framework,
      "CasePaths": .framework,
      "CasePathsCore": .framework,
      "Clocks": .framework,
      "CombineSchedulers": .framework,
      "ConcurrencyExtras": .framework,
      "CustomDump": .framework,
      "Dependencies": .framework,
      "DependenciesMacros": .framework,
      "IdentifiedCollections": .framework,
      "SwiftNavigation": .framework,
      "SwiftUINavigation": .framework,
      "UIKitNavigation": .framework,
      "UIKitNavigationShim": .framework,
      "Perception": .framework,
      "PerceptionCore": .framework,
      "IssueReporting": .framework,
      "IssueReportingPackageSupport": .framework,
      "XCTestDynamicOverlay": .framework,
      "InternalCollectionsUtilities": .framework,
      "OrderedCollections": .framework,
    ]
  )
#endif

let package = Package(
  name: "WePLiPackages",
  // Moya · Kingfisher · Supabase · GoogleSignIn · KeychainAccess는 계획된 스택(AGENTS.md)이지만 아직 쓰는 코드가 없어 뺐다.
  // 실제 API · 로그인 · 이미지를 붙이는 기능에서 그때 넣는다(#225).
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", .upToNextMinor(from: "1.23.3")),
  ]
)
