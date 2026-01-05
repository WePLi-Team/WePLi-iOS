// swift-tools-version: 6.0
import PackageDescription

#if TUIST
  import ProjectDescription
  import ProjectDescriptionHelpers

  let packageSettings = PackageSettings()
#endif

let package = Package(
  name: "WePLiPackages",
  dependencies: [
    .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.0.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
    .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
  ]
)
