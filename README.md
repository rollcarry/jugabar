# JugaBar 📈 (주가바)

**JugaBar** (주가바) is a lightweight, native macOS menu bar application that tracks real-time Korean stock prices (KOSPI & KOSDAQ). Built with Swift and SwiftUI, it is designed to be minimal, efficient, and playfully competitive.

The name **JugaBar** is a pun on the famous Korean ice cream **"누가바" (Nugabar)**. In Korean, **"주가바"** sounds like **"주가 봐" (Check the stock price)** and also literally means **"Stock Price (주가) Bar"**.

<div align="center">
  <video src="https://raw.githubusercontent.com/rollcarry/jugabar/main/jugabar.mp4" width="100%" controls></video>
</div>

## ✨ Features

- **Menu Bar Integration:** Resides discreetly in your menu bar with a clean icon.
- **Real-time Data:** Fetches live data directly from Naver Finance.
- **Dual-Market Support (NXT):** Fully supports **Nextade (NXT)**, Korea's first ATS, providing extended price tracking from 08:00 to 20:00 KST.
- **Smart Display Logic:** 
    *   **Main Market (09:00-15:30):** Clean view showing only KRX prices.
    *   **Extended/Night:** Dual view showing NXT prices (primary) and KRX closing prices (secondary).
- **"Beat the Market" Game:** Compete against the KOSPI/KOSDAQ indices. The app calculates your value-weighted performance and awards a **🏆 WIN** badge if you outperform the market.
- **Portfolio Mode:** Track your own holdings, quantities, and calculate real-time daily gains or total returns across both KRX and NXT sessions.
- **Native Performance:** Extremely low memory (~5MB) and CPU usage.

## 🕒 Display Schedule (KST)

| Time Period | Session | Display Mode | Primary Price | Secondary Price |
| :--- | :--- | :--- | :--- | :--- |
| **08:00 – 09:00** | NXT Pre-market | **Dual View** | **NXT** Live (`NXT` badge) | KRX Prev. Close |
| **09:00 – 15:30** | Main Market | **Single View** | **KRX** Live | (Hidden) |
| **15:30 – 20:00** | NXT After-market | **Dual View** | **NXT** Live (`NXT` badge) | KRX Final Close |
| **20:00 – 08:00** | Night Time | **Dual View** | **NXT** Final (`NXT·F` badge) | KRX Final Close |

## 🚀 Installation

### Via Homebrew (Recommended)

```bash
brew install --cask --no-quarantine rollcarry/jugabar/jugabar

# To upgrade
brew upgrade --cask --no-quarantine rollcarry/jugabar/jugabar

```

### Manual Installation

1.  **Download:** Get the latest `JugaBar.app` from [Releases](https://github.com/rollcarry/JugaBar/releases).
2.  **Install:** Drag `JugaBar.app` into your `/Applications` folder.
3.  **Run:** Open the app. You will see a small chart icon (📈) appear in your menu bar.

## 🛠 Building from Source

**Prerequisites:**
- macOS 13.0 (Ventura) or later.
- Swift command line tools installed.

```bash
# 1. Clone and Build
./build_dist.sh

# 2. Launch the app
open JugaBar.app
```

## 📄 License

MIT License
