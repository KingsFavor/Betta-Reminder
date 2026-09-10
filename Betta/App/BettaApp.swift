import SwiftUI
import AppKit

/// Shared identity for the single main window.
enum MainWindow { static let id = "betta.main" }

@main
struct BettaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var store = ReminderStore()
    @State private var updates = UpdateChecker()
    /// The scheduling tick. Held at App scope so it keeps running even when the
    /// window is closed (the app lives on in the menu bar).
    @State private var engine: ReminderEngine?
    /// Auto-relaunches into a Homebrew-upgraded bundle when the app is reactivated.
    @State private var relauncher = UpdateRelauncher()

    /// A menu-bar template rendering of the betta mark. The MenuBarIcon asset frames
    /// the *visible* fish (faint outer fin wisps trimmed), so the fish fills the frame
    /// with no baked-in whitespace. Drawn preserving aspect at ~full menu-bar height;
    /// macOS caps the icon at the bar's height, so this is about as large as it gets.
    private static let menuBarIcon: NSImage = {
        guard let src = NSImage(named: "MenuBarIcon") else { return NSImage() }
        let height: CGFloat = 26
        let aspect = src.size.width / max(1, src.size.height)
        let size = NSSize(width: (height * aspect).rounded(), height: height)
        let icon = NSImage(size: size)
        icon.lockFocus()
        src.draw(in: NSRect(origin: .zero, size: size))
        icon.unlockFocus()
        icon.isTemplate = true      // tint to match the menu bar (light/dark)
        return icon
    }()

    var body: some Scene {
        // A single unique window (not WindowGroup) so the Dock icon / "열기" focus
        // the one window instead of spawning duplicates.
        Window("Betta", id: MainWindow.id) {
            RootView()
                .environment(store)
                .environment(updates)
                .background(WindowConfigurator(store: store))
                .task {
                    if engine == nil {
                        let engine = ReminderEngine(store: store)
                        engine.start()
                        self.engine = engine
                        relauncher.start()
                    }
                    updates.checkOnLaunch()
                }
        }
        .defaultSize(width: 440, height: 600)
        .windowResizability(.contentMinSize)
        .commands { UpdateCommands(updates: updates) }

        MenuBarExtra {
            MenuBarContent()
                .environment(store)
        } label: {
            // The BettaLogo asset's 1x rep is the full-size (huge) art, and MenuBarExtra
            // sizes the status item to the image's *intrinsic* size — SwiftUI `.frame`
            // doesn't constrain it. So hand it a pre-scaled template NSImage instead.
            Image(nsImage: Self.menuBarIcon)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(store)
                .environment(updates)
        }
    }
}

/// Adds "업데이트 확인…" to the app menu.
struct UpdateCommands: Commands {
    let updates: UpdateChecker
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("업데이트 확인…") { updates.checkForUpdatesInteractive() }
        }
    }
}

/// Brings the existing window forward on a Dock-icon click (or reopens it if closed),
/// so the icon always leads back to the reminders + countdown.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
            }
        }
        sender.activate(ignoringOtherApps: true)
        return true
    }
}
