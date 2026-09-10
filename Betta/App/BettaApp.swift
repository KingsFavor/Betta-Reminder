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
            Image("BettaLogo")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 15, height: 15)
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
