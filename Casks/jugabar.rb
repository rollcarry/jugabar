cask "jugabar" do
  version "1.0.3"
  sha256 "f18b250b2770d91c1446fb0baa43297c015af021cca8910b0ea4605935c512fe"

  url "https://github.com/rollcarry/jugabar/releases/download/v#{version}/JugaBar-v#{version}.zip"
  name "JugaBar"
  desc "Real-time Korean stock prices in your menu bar"
  homepage "https://github.com/rollcarry/jugabar"

  app "JugaBar.app"

  zap trash: [
    "~/Library/Preferences/com.user.JugaBar.plist",
  ]
end
