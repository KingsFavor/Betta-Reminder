cask "betta" do
  version "__VERSION__"
  sha256 "__SHA256__"

  url "https://github.com/KingsFavor/Betta-Reminder/releases/download/v#{version}/Betta-#{version}.dmg",
      verified: "github.com/KingsFavor/Betta-Reminder/"
  name "Betta"
  desc "Minimal always-on-top interval reminders for macOS"
  homepage "https://github.com/KingsFavor/Betta-Reminder"

  depends_on macos: :sonoma

  app "Betta.app"

  zap trash: [
    "~/Library/Application Support/com.dws.betta",
    "~/Library/Caches/com.dws.betta",
    "~/Library/HTTPStorages/com.dws.betta",
    "~/Library/Preferences/com.dws.betta.plist",
  ]
end
