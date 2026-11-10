// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swiftui-alert-state",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
  ],
  products: [
    .library(name: "SwiftUIAlertState", targets: ["SwiftUIAlertState"])
  ],
  targets: [
    .target(name: "SwiftUIAlertState"),
    .testTarget(
      name: "SwiftUIAlertStateTests",
      dependencies: ["SwiftUIAlertState"]
    ),
  ]
)
