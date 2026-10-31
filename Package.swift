// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Sideboard",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "SideloadKit", targets: ["SideloadKit"]),
    ],
    targets: [
        .target(name: "SideloadKit"),
        .testTarget(name: "SideloadKitTests", dependencies: ["SideloadKit"]),
    ]
)
