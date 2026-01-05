import ProjectDescription
import ProjectDescriptionHelpers

// --- Build Scripts ---
let swiftLintScript: TargetScript = .pre(
  script: #"""
  set -euo pipefail
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  if command -v swiftlint >/dev/null 2>&1; then
    echo "Running SwiftLint (non-strict)…"
    swiftlint --quiet --config "$ROOT/.swiftlint.yml" || true
  else
    echo "warning: SwiftLint not installed"
  fi

  # 의존성 분석용 스탬프 생성
  touch "${DERIVED_FILE_DIR}/SwiftLint.stamp"
  """#,
  name: "SwiftLint (non-strict)",
  outputPaths: ["$(DERIVED_FILE_DIR)/SwiftLint.stamp"],
  basedOnDependencyAnalysis: true
)

// --- Project ---
let project = Project(
  name: "WePLi",
  settings: .settings(
    base: SharedSettings.base.base,
    configurations: [
      .debug(name: "Debug", xcconfig: .relativeToRoot("Configs/Debug.xcconfig")),
      .release(name: "Release", xcconfig: .relativeToRoot("Configs/Release.xcconfig")),
    ]
  ),
  targets: [
    .target(
      name: "WePLi",
      destinations: [.iPhone],
      product: .app,
      bundleId: "com.example.wepli",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [:],
        "API_BASE_URL": "$(API_BASE_URL)",
        "LOG_LEVEL": "$(LOG_LEVEL)",
        "CFBundleURLTypes": [
          [
            "CFBundleURLName": "com.example.wepli",
            "CFBundleURLSchemes": ["$(GOOGLE_REVERSED_CLIENT_ID)"],
          ],
        ],
      ]),
      sources: ["Sources/**", "Generated/**"],
      resources: ["Resources/**"],
      entitlements: .file(path: .relativeToManifest("App.entitlements")),
      scripts: [
        swiftLintScript,
      ],
      dependencies: [
        .external(name: "Moya"),
        .external(name: "Kingfisher"),
        .external(name: "ComposableArchitecture"),
        .external(name: "GoogleSignIn"),
        .external(name: "GoogleSignInSwift"),
        .external(name: "Supabase"),
        .external(name: "KeychainAccess"),
      ]
    ),
    .target(
      name: "WePLiTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.example.wepli.tests",
      infoPlist: .default,
      sources: ["Tests/**"],
      dependencies: [.target(name: "WePLi")]
    ),
  ]
)
