cask "jugabar" do
  version "1.0.6"
  sha256 "4e0621e450dd1e8104f5ec0d5ed7f29ca6d60aecca82a1052f8f82c4bf5386da"

  url "https://github.com/rollcarry/jugabar/releases/download/v#{version}/JugaBar-v#{version}.zip"
  name "JugaBar"
  desc "Real-time Korean stock prices in your menu bar"
  homepage "https://github.com/rollcarry/jugabar"

  app "JugaBar.app"

  zap trash: [
    "~/Library/Preferences/com.user.JugaBar.plist",
  ]
end
