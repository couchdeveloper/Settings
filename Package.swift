// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Settings",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Settings",
            targets: ["Settings"]
        ),
        .library(
            name: "SettingsMock",
            targets: ["SettingsMock"]
        ),
        .executable(
            name: "SettingsClient",
            targets: ["SettingsClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation
        .macro(
            name: "SettingsMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "Settings", 
            dependencies: [
                "SettingsMacros",
                .product(name: "Atomics", package: "swift-atomics"),
            ]
        ),
        
        // Library that exposes a Mock for Foundation's UserDefaults,
        // which can be used for testing UserDefaults use cases.
        .target(
            name: "SettingsMock",
            dependencies: [
                "Settings",
            ]
        ),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(
            name: "SettingsClient", 
            dependencies: [
                "Settings",
                "SettingsMock"
            ]
        ),

        // Test utilities and helpers
        .target(
            name: "Utilities",
            dependencies: [
            ],
            path: "Tests/Utilities"
        ),

        // A test target used to test the Settings functionality
        .testTarget(
            name: "SettingsTests",
            dependencies: [
                "Settings",
                "Utilities",
                // "SettingsMacros",
                // .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SettingsMacroExpansionTests",
            dependencies: [
                "Settings",
                "SettingsMacros",
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SettingsMockTests",
            dependencies: [
                "SettingsMock",
                "Utilities",
                // "SettingsMacros",
                // .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
