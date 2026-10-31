import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Build Scripts

let swiftLintScript: TargetScript = .pre(
  script: #"""
  set -euo pipefail
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  # Xcode 빌드 단계는 셸 설정을 읽지 않아 mise · Homebrew 경로를 직접 더한다
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
  SWIFTLINT="$(cd "$ROOT" && mise which swiftlint 2>/dev/null || command -v swiftlint || true)"

  if [ -n "$SWIFTLINT" ]; then
    echo "Running SwiftLint (non-strict)…"
    "$SWIFTLINT" --quiet --config "$ROOT/.swiftlint.yml" || true
  else
    echo "warning: SwiftLint not installed — mise install"
  fi

  # 의존성 분석용 스탬프 생성
  touch "${DERIVED_FILE_DIR}/SwiftLint.stamp"
  """#,
  name: "SwiftLint (non-strict)",
  outputPaths: ["$(DERIVED_FILE_DIR)/SwiftLint.stamp"],
  basedOnDependencyAnalysis: true
)

// MARK: - Project

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
        // UI-3g 이미지 저장 — 원본에 없는 문구(확인 필요)
        "NSPhotoLibraryAddUsageDescription": "곡 공유 카드를 사진 앱에 저장하려면 사진 추가 권한이 필요해요.",
        "CFBundleURLTypes": [
          [
            "CFBundleURLName": "com.example.wepli",
            "CFBundleURLSchemes": ["$(GOOGLE_REVERSED_CLIENT_ID)"],
          ],
        ],
      ]),
      sources: ["Sources/**", "Generated/**", "Shared/Sources/**"],
      resources: ["Resources/**"],
      entitlements: .file(path: .relativeToManifest("App.entitlements")),
      scripts: [
        swiftLintScript,
      ],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .target(name: "WePLiWidget"),
      ]
    ),
    // DEC-015 · UI-13e 잠금화면 위젯
    .target(
      name: "WePLiWidget",
      destinations: [.iPhone],
      product: .appExtension,
      bundleId: "com.example.wepli.widget",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "WePLi",
        "NSExtension": [
          "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
        ],
      ]),
      sources: ["Widget/Sources/**", "Shared/Sources/**"],
      entitlements: .file(path: .relativeToManifest("Widget/WePLiWidget.entitlements"))
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
