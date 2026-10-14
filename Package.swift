// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YpsoPumpKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "YpsoPumpKit", targets: ["YpsoPumpKit"]),
        .library(name: "YpsoPumpSimulator", targets: ["YpsoPumpSimulator"]),
        .executable(name: "ypso-simulator", targets: ["YpsoSimulatorCLI"])
    ],
    targets: [
        .target(name: "YpsoPumpKit"),
        .target(name: "YpsoPumpSimulator", dependencies: ["YpsoPumpKit"]),
        .executableTarget(name: "YpsoSimulatorCLI", dependencies: ["YpsoPumpSimulator"]),
        .testTarget(name: "YpsoPumpKitTests", dependencies: ["YpsoPumpKit", "YpsoPumpSimulator"])
    ]
)
