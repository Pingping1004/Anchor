// swift-tools-version: 6.0

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Anchor",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .iOSApplication(
            name: "Anchor",
            targets: ["AppModule"],
            bundleIdentifier: "PingOrg.Anchor",
            teamIdentifier: "F9XTLDJA6D",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .asset("AccentColor"),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/elai950/AlertToast.git", "1.3.9"..<"2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "AlertToast", package: "alerttoast")
            ],
            path: "."
        )
    ],
    swiftLanguageModes: [.version("6")]
)
