// swift-tools-version:6.4

import PackageDescription

let package = Package(
    name: "VaporSecurityHeaders",
    platforms: [
        .macOS("26.2")
    ],
    products: [
        .library(name: "VaporSecurityHeaders", targets: ["VaporSecurityHeaders"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", exact: "5.0.0-beta.3")
    ],
    targets: [
        .target(name: "VaporSecurityHeaders", dependencies: [
            .product(name: "Vapor", package: "vapor")
        ]),
        .testTarget(
            name: "VaporSecurityHeadersTests",
            dependencies: [
                "VaporSecurityHeaders",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ]
)
