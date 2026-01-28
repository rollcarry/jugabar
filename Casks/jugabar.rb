cask "jugabar" do
  version "1.0.0"
  sha256 "271dc67180fcf3535174f22ca6808e6e2a52d0a6124c0f9a728ac8d4f44443ce"

  url "https://github.com/rollcarry/jugabar/releases/download/v#{version}/JugaBar-v#{version}.zip"
  name "JugaBar"
  desc "Real-time Korean stock prices in your menu bar"
  homepage "https://github.com/rollcarry/jugabar"

  app "JugaBar.app"

  zap trash: [
    "~/Library/Preferences/com.user.JugaBar.plist",
  ]
end
