// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Vector2FA",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Run", targets: ["Run"])
    ],
    dependencies: [
        // Web framework + HTTP
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // ORM
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.0"),
        // APNs (note: package identity is *lowercase* "apns")
        .package(url: "https://github.com/vapor/apns.git", from: "4.2.0"),
        // Crypto (ECDSA, ChaChaPoly, HMAC)
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.14.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "APNS", package: "apns"),
                .product(name: "Crypto", package: "swift-crypto")
            ],
            resources: [
                // Bundle your APNs key so configure.swift can read it
                .copy("Config/apns-auth-key.p8")
            ]
        ),
        .executableTarget(
            name: "Run",
            dependencies: ["App"]
        )
    ]
)
