# Repository Guidelines

## Project Structure & Module Organization

JugaBar is a Swift Package Manager project for a native macOS menu bar app. App and shared model code live in `Sources/JugaBar/`. `Package.swift` exposes `JugaBarCore` from `StockModels.swift` and `Int+Formatting.swift`, then builds the `JugaBar` executable from the SwiftUI views, `AppDelegate`, and `StockService`. The lightweight local test helper is in `Sources/Testing/`. Tests are in `Tests/`, with package tests under `Tests/JugaBarTests/` and a standalone model test runner at `Tests/StockModelTests.swift`. Release assets and packaging files are at the root: `Info.plist`, `JugaBar.icns`, `build_dist.sh`, and `Casks/jugabar.rb`.

## Build, Test, and Development Commands

- `swift build`: build all package targets for local development.
- `swift run JugaBar`: run the menu bar executable from SPM.
- `swift test`: run the SPM test target.
- `./Tests/run_tests.sh`: compile and run the standalone stock model tests used for focused model validation.
- `VERSION=1.0.7 ./build_dist.sh`: build a release binary, create `JugaBar.app`, zip it, and print the SHA-256 checksum.
- `open JugaBar.app`: launch the packaged app after `build_dist.sh`.

## Coding Style & Naming Conventions

Use Swift 5.9+ conventions with 4-space indentation and clear value-type models. Keep UI in SwiftUI views named `*View.swift`, reusable UI components as descriptive nouns such as `StockRow.swift`, and service logic in `*Service.swift`. Prefer `async`/`await` for network work and keep UI-facing state updates on the main actor. Preserve `StockService` as the main source of truth for stock, portfolio, refresh, and market-session state.

## Testing Guidelines

Add tests for model parsing, numeric conversions, portfolio gain calculations, and NXT/KRX session logic when changing data behavior. Name tests by behavior, for example `unsigned nxt rate still respects falling flag`. Run `swift test` for package integration and `./Tests/run_tests.sh` before changes that touch `StockModels.swift` or `Int+Formatting.swift`.

## Commit & Pull Request Guidelines

Recent commits use concise Conventional Commit prefixes such as `fix:`, `chore:`, and `refactor:`. Follow that pattern: `fix: daily gain for signed NXT values`. Pull requests should include a short problem summary, the user-visible change, test results, and screenshots or a short recording for UI changes. Link related issues when available and mention release impacts, including `Casks/jugabar.rb` or version/checksum updates.

## Security & Configuration Tips

Do not commit signing keys, API secrets, or local build artifacts. The app fetches market data from Naver Finance, so keep parsing changes defensive against missing fields and changed response shapes.
