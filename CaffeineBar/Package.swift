// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CaffeineBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CaffeineBar", targets: ["CaffeineBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "CaffeineBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources",
            resources: [
                .copy("Sounds"),
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "CaffeineBarTests",
            dependencies: ["CaffeineBar"],
            path: "Tests"
        )
    ]
)
