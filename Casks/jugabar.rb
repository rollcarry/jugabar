cask "jugabar" do
  version "1.0.4"
  sha256 "2192aef8e9c9bb1215d61d00871064a64fa93361550aac294b69fc84c237cde7"

  url "https://github.com/rollcarry/jugabar/releases/download/v#{version}/JugaBar-v#{version}.zip"
  name "JugaBar"
  desc "Real-time Korean stock prices in your menu bar"
  homepage "https://github.com/rollcarry/jugabar"

  app "JugaBar.app"

  zap trash: [
    "~/Library/Preferences/com.user.JugaBar.plist",
  ]
end
