// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "bonsai",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "Bonsai", targets: ["Bonsai"])
  ],
  targets: [
    .executableTarget(
      name: "Bonsai",
      path: "Sources/Bonsai"
    ),
    .testTarget(
      name: "BonsaiTests",
      dependencies: ["Bonsai"],
      path: "Tests/BonsaiTests"
    )
  ]
)
