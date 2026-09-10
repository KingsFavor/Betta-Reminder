import Foundation

/// A single reminder the user configures. All fields are local and Codable — the
/// whole list is persisted as one JSON file (see `ReminderStore`).
struct Reminder: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    /// Body text for a plain reminder. Ignored by rich templates, which supply their own.
    var message: String
    var template: ReminderTemplate
    var schedule: Schedule
    var isEnabled: Bool
    /// Advances every time a rich template actually fires, so poses/tips rotate.
    var richCursor: Int
    var createdAt: Date

    init(id: UUID = UUID(),
         title: String,
         message: String = "",
         template: ReminderTemplate = .plain,
         schedule: Schedule = .plainDefault,
         isEnabled: Bool = true,
         richCursor: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.message = message
        self.template = template
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.richCursor = richCursor
        self.createdAt = createdAt
    }

    /// A fresh reminder seeded from a template (used by the "add" flow).
    static func seeded(from template: ReminderTemplate) -> Reminder {
        Reminder(title: template.seedTitle,
                 template: template,
                 schedule: template.seedSchedule)
    }

    /// The next time this reminder will fire, or nil if disabled / never.
    func nextFire(after reference: Date = Date()) -> Date? {
        guard isEnabled else { return nil }
        return schedule.nextFireDate(after: reference)
    }

    /// Title shown in lists, falling back to the template name for an unnamed reminder.
    var resolvedTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? template.displayName : trimmed
    }
}
