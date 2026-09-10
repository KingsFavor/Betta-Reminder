import AppKit
import SwiftUI

/// Which screen corner popups anchor to (and stack from).
enum PopupCorner: String, Codable, CaseIterable, Identifiable {
    case topLeft, topRight, bottomLeft, bottomRight
    var id: String { rawValue }

    var label: String {
        switch self {
        case .topLeft:     return "좌측 상단"
        case .topRight:    return "우측 상단"
        case .bottomLeft:  return "좌측 하단"
        case .bottomRight: return "우측 하단"
        }
    }

    /// SF Symbol hinting the corner.
    var symbol: String {
        switch self {
        case .topLeft:     return "arrow.up.left"
        case .topRight:    return "arrow.up.right"
        case .bottomLeft:  return "arrow.down.left"
        case .bottomRight: return "arrow.down.right"
        }
    }

    var isTop: Bool { self == .topLeft || self == .topRight }
    var isLeft: Bool { self == .topLeft || self == .bottomLeft }
}

/// Presents reminder popups as **floating panels above every other window** — including
/// other apps and full-screen spaces. Panels anchor to the chosen screen corner, stack
/// away from it, fade in, and fade out after each reminder's own duration.
///
/// Multiple *different* reminders can be on screen at once; the same reminder is never
/// stacked twice — if it's already showing, a re-fire is ignored.
@MainActor
final class PopupPresenter {
    static let shared = PopupPresenter()
    private init() {}

    private struct Active {
        let panel: NSPanel
        let reminderID: UUID
    }
    private var actives: [Active] = []          // newest first
    private var corner: PopupCorner = .topRight

    private let margin: CGFloat = 16
    private let gap: CGFloat = 10
    private let width: CGFloat = 320

    /// Show a popup for `reminder`. `duration` ≤ 0 keeps it until closed. `corner`
    /// sets where popups anchor. A reminder already on screen is not shown again;
    /// returns whether a popup was actually presented.
    @discardableResult
    func present(_ reminder: Reminder, duration: Double, corner: PopupCorner) -> Bool {
        self.corner = corner
        guard !actives.contains(where: { $0.reminderID == reminder.id }) else { return false }

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
        hosting.layoutSubtreeIfNeeded()
        let fitted = hosting.fittingSize
        panel.setContentSize(NSSize(width: width, height: max(fitted.height, 88)))

        actives.insert(Active(panel: panel, reminderID: reminder.id), at: 0)
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
                guard let self, let panel, self.actives.contains(where: { ObjectIdentifier($0.panel) == id })
                else { return }
                self.dismiss(panel)
            }
        }
        return true
    }

    // MARK: Panel lifecycle

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: 100),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
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
        guard actives.contains(where: { $0.panel === panel }) else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self, weak panel] in
            MainActor.assumeIsolated {
                guard let self, let panel else { return }
                panel.orderOut(nil)
                self.actives.removeAll { $0.panel === panel }
                self.reflow(animated: true)
            }
        })
    }

    /// Stack panels away from the anchored corner.
    private func reflow(animated: Bool) {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let x = corner.isLeft ? vf.minX + margin : vf.maxX - margin - width

        if corner.isTop {
            var y = vf.maxY - margin
            for a in actives {
                let h = a.panel.frame.height
                setFrame(a.panel, NSRect(x: x, y: y - h, width: width, height: h), animated)
                y -= (h + gap)
            }
        } else {
            var y = vf.minY + margin
            for a in actives {
                let h = a.panel.frame.height
                setFrame(a.panel, NSRect(x: x, y: y, width: width, height: h), animated)
                y += (h + gap)
            }
        }
    }

    private func setFrame(_ panel: NSPanel, _ frame: NSRect, _ animated: Bool) {
        if animated { panel.animator().setFrame(frame, display: true) }
        else { panel.setFrame(frame, display: true) }
    }
}
