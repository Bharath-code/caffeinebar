// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CaffeineBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CaffeineBar", targets: ["CaffeineBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", .upToNextMinor(from: "2.6.0"))
    ],
    targets: [
        .executableTarget(
            name: "CaffeineBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources",
            exclude: ["Info.plist"],
            resources: [
                .copy("Sounds"),
                .process("Assets.xcassets")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Info.plist",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        ),
        .testTarget(
            name: "CaffeineBarTests",
            dependencies: ["CaffeineBar"],
            path: "Tests"
        )
    ]
)
