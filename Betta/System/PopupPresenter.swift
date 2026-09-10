import AppKit
import SwiftUI

/// Presents reminder popups as **floating panels that sit above every other window**
/// — including other apps and full-screen spaces — which is the whole point of the
/// app (the spec asks for an in-app popup, not a Notification Center banner).
///
/// Panels stack down the top-right corner, fade in, and fade themselves out after the
/// configured duration. They never steal focus (`.nonactivatingPanel`), so they don't
/// interrupt what the user is typing.
@MainActor
final class PopupPresenter {
    static let shared = PopupPresenter()
    private init() {}

    /// Live panels, top-most first, used to stack and to reflow when one closes.
    private var panels: [NSPanel] = []

    private let margin: CGFloat = 16
    private let gap: CGFloat = 10
    private let width: CGFloat = 320

    /// Show a popup for `reminder`. `duration` ≤ 0 keeps it until manually closed.
    func present(_ reminder: Reminder, duration: Double) {
        let panel = makePanel()
        let onClose: () -> Void = { [weak self, weak panel] in
            guard let panel else { return }
            self?.dismiss(panel)
        }

        let content = PopupView(reminder: reminder, onClose: onClose)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)

        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hosting

        // Size to the SwiftUI content, then place it.
        hosting.layoutSubtreeIfNeeded()
        let fitted = hosting.fittingSize
        let size = NSSize(width: width, height: max(fitted.height, 88))
        panel.setContentSize(size)

        panels.insert(panel, at: 0)
        reflow(animated: false)

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            panel.animator().alphaValue = 1
        }

        if duration > 0 {
            let id = ObjectIdentifier(panel)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, weak panel] in
                guard let self, let panel, self.panels.contains(where: { ObjectIdentifier($0) == id })
                else { return }
                self.dismiss(panel)
            }
        }
    }

    // MARK: Panel lifecycle

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: 100),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        // Above normal, floating, and menu-bar-owning windows — including over
        // full-screen apps. `.statusBar`-level keeps it above almost everything
        // while staying below the screen-saver/alert shields.
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .none
        return panel
    }

    private func dismiss(_ panel: NSPanel) {
        guard panels.contains(where: { $0 === panel }) else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self, weak panel] in
            // Animation completion runs on the main thread; assert that to the compiler.
            MainActor.assumeIsolated {
                guard let self, let panel else { return }
                panel.orderOut(nil)
                self.panels.removeAll { $0 === panel }
                self.reflow(animated: true)
            }
        })
    }

    /// Stack panels down the top-right corner of the main screen.
    private func reflow(animated: Bool) {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        var y = vf.maxY - margin
        for panel in panels {
            let h = panel.frame.height
            let x = vf.maxX - margin - width
            let frame = NSRect(x: x, y: y - h, width: width, height: h)
            if animated {
                panel.animator().setFrame(frame, display: true)
            } else {
                panel.setFrame(frame, display: true)
            }
            y -= (h + gap)
        }
    }
}
