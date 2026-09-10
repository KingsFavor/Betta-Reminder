import SwiftUI
import AppKit

/// Bridges SwiftUI to the host `NSWindow` so the main window can float above other
/// apps' windows ("항상 위에 고정"), like TaskOcean's pin.
///
/// A plain `View` (not the representable) on purpose: it *reads* `store.alwaysOnTop`
/// in `body`, so toggling the pin re-evaluates it and pushes the fresh value into the
/// bridge — otherwise `updateNSView` wouldn't fire and unpinning wouldn't drop the level.
struct WindowConfigurator: View {
    var store: ReminderStore
    var body: some View {
        WindowConfigBridge(alwaysOnTop: store.alwaysOnTop)
    }
}

private struct WindowConfigBridge: NSViewRepresentable {
    var alwaysOnTop: Bool

    func makeNSView(context: Context) -> NSView {
        let view = TrackerView()
        view.onResolve = { window in apply(to: window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        apply(to: window)
    }

    private func apply(to window: NSWindow) {
        // Floating keeps us above normal windows but below full-screen apps.
        window.level = alwaysOnTop ? .floating : .normal
        window.collectionBehavior = alwaysOnTop
            ? [.managed, .fullScreenAuxiliary]
            : [.managed]
    }

    /// Small NSView that resolves its host window once attached.
    final class TrackerView: NSView {
        var onResolve: ((NSWindow) -> Void)?
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { onResolve?(window) }
        }
    }
}
