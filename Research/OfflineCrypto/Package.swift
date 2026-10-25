// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "YpsoOfflineCrypto",
    products: [.library(name: "OfflineCrypto", targets: ["OfflineCrypto"])],
    dependencies: [.package(path: "../..")],
    targets: [
        .systemLibrary(name: "CSodium", pkgConfig: "libsodium", providers: [.apt(["libsodium-dev"]), .brew(["libsodium"])]),
        .systemLibrary(name: "CSQLite", pkgConfig: "sqlite3", providers: [.apt(["libsqlite3-dev"])]),
        .target(name: "OfflineCrypto", dependencies: ["CSodium", "CSQLite", .product(name: "YpsoPumpKit", package: "YpsoPumpKit")]),
        .testTarget(name: "OfflineCryptoTests", dependencies: ["OfflineCrypto", "YpsoPumpKit"], resources: [.copy("Fixtures")])
    ])
