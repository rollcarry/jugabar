cask "jugabar" do
  version "1.0.3"
  sha256 "ef43770f4e28cf5960af373254b8ae92988ec7f4d59c6b2f56b021d4f1099518"

  url "https://github.com/rollcarry/jugabar/releases/download/v#{version}/JugaBar-v#{version}.zip"
  name "JugaBar"
  desc "Real-time Korean stock prices in your menu bar"
  homepage "https://github.com/rollcarry/jugabar"

  app "JugaBar.app"

  zap trash: [
    "~/Library/Preferences/com.user.JugaBar.plist",
  ]
end
