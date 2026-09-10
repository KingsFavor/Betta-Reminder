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
    /// How long this reminder's popup stays before fading on its own, in seconds.
    /// `0` means keep it until the user closes it ("항상 유지").
    var popupDurationSeconds: Int
    var createdAt: Date

    /// Sentinel for "keep until closed".
    static let keepAlways = 0

    init(id: UUID = UUID(),
         title: String,
         message: String = "",
         template: ReminderTemplate = .plain,
         schedule: Schedule = .plainDefault,
         isEnabled: Bool = true,
         richCursor: Int = 0,
         popupDurationSeconds: Int = 20,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.message = message
        self.template = template
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.richCursor = richCursor
        self.popupDurationSeconds = popupDurationSeconds
        self.createdAt = createdAt
    }

    // Tolerant decoding so older saved data (missing newer fields) still loads.
    enum CodingKeys: String, CodingKey {
        case id, title, message, template, schedule, isEnabled, richCursor, popupDurationSeconds, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        message = try c.decodeIfPresent(String.self, forKey: .message) ?? ""
        template = try c.decodeIfPresent(ReminderTemplate.self, forKey: .template) ?? .plain
        schedule = try c.decodeIfPresent(Schedule.self, forKey: .schedule) ?? .plainDefault
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        richCursor = try c.decodeIfPresent(Int.self, forKey: .richCursor) ?? 0
        popupDurationSeconds = try c.decodeIfPresent(Int.self, forKey: .popupDurationSeconds) ?? 20
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
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
