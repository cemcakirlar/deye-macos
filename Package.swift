// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeyeMacOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DeyeMacOS", targets: ["DeyeMacOS"])
    ],
    targets: [
        .executableTarget(
            name: "DeyeMacOS",
            path: "DeyeMacOS",
            exclude: [
                "Resources/Info.plist",
                "Resources/DeyeMacOS.entitlements",
                "Resources/Assets.xcassets"
            ]
        )
    ]
)
