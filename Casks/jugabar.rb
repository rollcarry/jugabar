cask "jugabar" do
  version "1.0.1"
  sha256 "282f52ef0e64fef5ff23ac3e4d265e40b51eb50bb502d47ac12bddf735707afc"

  url "https://github.com/rollcarry/jugabar/releases/download/v#{version}/JugaBar-v#{version}.zip"
  name "JugaBar"
  desc "Real-time Korean stock prices in your menu bar"
  homepage "https://github.com/rollcarry/jugabar"

  app "JugaBar.app"

  zap trash: [
    "~/Library/Preferences/com.user.JugaBar.plist",
  ]
end
