import AppKit
import Foundation

/// Drives when reminders fire.
///
/// Rather than juggle one OS timer per reminder, a single lightweight tick checks the
/// list every `tickInterval`. On each tick it asks each enabled reminder whether it had
/// a fire time in the window `(lastTick, now]`; if so it fires **once** (missed fires
/// during sleep are coalesced, so waking your Mac after lunch shows one nudge, not ten).
/// A minute-granular reminder is punctual to within the tick.
@MainActor
final class ReminderEngine {
    private let store: ReminderStore
    private let presenter = PopupPresenter.shared
    private var timer: Timer?
    private var lastTick = Date()

    /// 15s keeps popups punctual while costing effectively nothing when idle.
    private let tickInterval: TimeInterval = 15

    init(store: ReminderStore) {
        self.store = store
    }

    func start() {
        lastTick = Date()
        let timer = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // .common so it keeps firing while the user drags a menu / window.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        // Also re-check right after the machine wakes, so a nudge isn't delayed a
        // whole tick past a long sleep.
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        let now = Date()
        defer { lastTick = now }
        // Guard against clock jumps producing a negative/empty window.
        let windowStart = min(lastTick, now)
        for reminder in store.reminders where reminder.isEnabled {
            guard let fireDate = reminder.schedule.nextFireDate(after: windowStart) else { continue }
            if fireDate <= now {
                fire(reminder)
            }
        }
    }

    /// Fire one reminder now: show its popup (the office-stretch template shows the
    /// whole routine at once, so there's no per-fire rotation to advance).
    private func fire(_ reminder: Reminder) {
        presenter.present(reminder,
                          duration: Double(reminder.popupDurationSeconds),
                          corner: store.popupCorner)
    }

    /// The "테스트" action: show exactly how this reminder will look, right now,
    /// without touching the schedule or the rotation cursor.
    func test(_ reminder: Reminder) {
        presenter.present(reminder,
                          duration: Double(reminder.popupDurationSeconds),
                          corner: store.popupCorner)
    }
}
