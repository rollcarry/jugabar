# JugaBar

**JugaBar** (주가바) is a lightweight, native macOS menu bar application designed for tracking real-time Korean stock prices (KOSPI & KOSDAQ). It offers a minimal, resource-efficient alternative to web-based tickers, integrating directly into the macOS menu bar.

The name is a pun on the "Nugabar" ice cream, sounding like "Check the stock price" (주가 봐) in Korean.

## Project Overview

*   **Type:** Native macOS Application
*   **Language:** Swift 5.9+
*   **Framework:** SwiftUI, Combine
*   **Platform:** macOS 13.0 (Ventura) or later
*   **Data Source:** Naver Finance (Internal API)

### Key Features
*   **Nextade (NXT) Integration:** Supports extended trading hours (08:00 - 20:00) with dual-market price display.
*   **"Beat the Market" Gaming:** Value-weighted portfolio performance comparison against KOSPI/KOSDAQ indices.
*   **Smart Refresh:** Efficient data fetching with support for auto-intervals or "Manual on Click" mode.
*   **Portfolio Management:** Tracks holdings, average buy prices, and calculates real-time gains/returns.

## Architecture

The project follows a standard SwiftUI architecture with a central service for data management.

*   **Entry Point:** `Sources/JugaBar/JugaBarApp.swift` initializes the app and injects the `AppDelegate`.
*   **Data Layer:** `Sources/JugaBar/StockService.swift` is the core `ObservableObject`.
    *   **NXT Support:** Parses `overMarketPriceInfo` to provide ATS session data.
    *   **Market Awareness:** Tracks `marketStatus` to toggle between main and extended trading logic.
    *   **Value-Weighted Return:** Calculates portfolio performance relative to market benchmarks.
*   **Build System:** Swift Package Manager (SPM). `build_dist.sh` handles bundling into a `.app` and generating distribution zips.

## Display Logic (KST)

| Time | Session | UI State |
| :--- | :--- | :--- |
| 08:00 - 09:00 | NXT Pre-market | Dual View (NXT primary) |
| 09:00 - 15:30 | Main Market | Single View (KRX only) |
| 15:30 - 20:00 | NXT After-market | Dual View (NXT primary) |
| 20:00 - 08:00 | Overnight | Dual View (NXT Final / KRX Final) |

## Building and Running

### Build Commands
```bash
# Standard Build
swift build

# Release Build & Bundle
./build_dist.sh
```

## Development Conventions

*   **Concurrency:** Async/await is used for all network calls. UI updates are handled on the `@MainActor`.
*   **State Management:** `StockService` acts as the single source of truth.
*   **Persistence:** `UserDefaults` stores watched codes, JSON-encoded portfolio data, and user preferences.
*   **UI:** Pure SwiftUI with an `AppDelegate` for status bar and popover lifecycle management.