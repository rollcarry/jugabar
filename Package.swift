// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JugaBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "JugaBarCore",
            path: "Sources/JugaBar",
            sources: [
                "StockModels.swift",
                "Int+Formatting.swift"
            ]
        ),
        .executableTarget(
            name: "JugaBar",
            dependencies: ["JugaBarCore"],
            path: "Sources/JugaBar",
            sources: [
                "AddBuyView.swift",
                "AppDelegate.swift",
                "ContentView.swift",
                "JugaBarApp.swift",
                "NotificationExtension.swift",
                "PerformanceBadge.swift",
                "PortfolioChartView.swift",
                "PortfolioEditView.swift",
                "SearchView.swift",
                "SettingsView.swift",
                "StockRow.swift",
                "StockService.swift"
            ]
        ),
        .target(
            name: "Testing",
            dependencies: ["JugaBarCore"],
            path: "Sources/Testing",
            sources: ["Testing.swift"]
        ),
        .testTarget(
            name: "JugaBarTests",
            dependencies: ["Testing"]
        ),
    ]
)
