cask "jugabar" do
  version "1.0.2"
  sha256 "c32bec12482926f05e78b9eb367f0a9752a72b3b8334d7800afff18241c9ff14"

  url "https://github.com/rollcarry/jugabar/releases/download/v#{version}/JugaBar-v#{version}.zip"
  name "JugaBar"
  desc "Real-time Korean stock prices in your menu bar"
  homepage "https://github.com/rollcarry/jugabar"

  app "JugaBar.app"

  zap trash: [
    "~/Library/Preferences/com.user.JugaBar.plist",
  ]
end
