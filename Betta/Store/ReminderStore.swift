import SwiftUI
import Observation

/// The single source of truth for the reminder list and app settings.
///
/// Everything is **local**: the list is one JSON file in Application Support, and
/// the two lightweight settings live in `UserDefaults`. Mutations save immediately
/// (small file, human-scale list) so a crash never loses an edit.
@MainActor
@Observable
final class ReminderStore {
    private(set) var reminders: [Reminder] = []

    /// Which screen corner popups anchor to (applies to all reminders).
    var popupCorner: PopupCorner {
        didSet { UserDefaults.standard.set(popupCorner.rawValue, forKey: Keys.popupCorner) }
    }

    /// Keep the main window floating above other apps' windows.
    var alwaysOnTop: Bool {
        didSet { UserDefaults.standard.set(alwaysOnTop, forKey: Keys.alwaysOnTop) }
    }

    private enum Keys {
        static let popupCorner = "popup.corner"
        static let alwaysOnTop = "window.alwaysOnTop"
    }

    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("com.dws.betta", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("reminders.json")

        let raw = UserDefaults.standard.string(forKey: Keys.popupCorner)
        self.popupCorner = raw.flatMap(PopupCorner.init(rawValue:)) ?? .topRight
        self.alwaysOnTop = UserDefaults.standard.bool(forKey: Keys.alwaysOnTop)

        load()
    }

    // MARK: Derived

    /// The soonest upcoming fire across all enabled reminders.
    var nextUp: (reminder: Reminder, date: Date)? {
        let now = Date()
        return reminders
            .compactMap { r in r.nextFire(after: now).map { (r, $0) } }
            .min { $0.1 < $1.1 }
            .map { (reminder: $0.0, date: $0.1) }
    }

    var enabledCount: Int { reminders.filter(\.isEnabled).count }

    // MARK: CRUD

    func add(_ reminder: Reminder) {
        reminders.append(reminder)
        save()
    }

    func update(_ reminder: Reminder) {
        guard let i = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[i] = reminder
        save()
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        save()
    }

    func setEnabled(_ reminder: Reminder, _ enabled: Bool) {
        guard let i = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[i].isEnabled = enabled
        save()
    }

    /// Advance a rich template's rotation cursor after it fires (so poses cycle).
    func advanceRichCursor(_ id: UUID) {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[i].richCursor &+= 1
        save()
    }

    func reminder(id: UUID) -> Reminder? { reminders.first { $0.id == id } }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            reminders = []
            return
        }
        reminders = (try? JSONDecoder().decode([Reminder].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(reminders) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
