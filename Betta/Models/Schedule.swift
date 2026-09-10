import Foundation

/// A recurring schedule: fire every `intervalMinutes` inside a daily active window,
/// on the selected weekdays. This is the whole recurrence model — deliberately small
/// so the picker can stay a few taps ("every 50 min · 09–18 · weekdays").
struct Schedule: Codable, Equatable, Hashable {
    /// Gap between fires, in minutes. Also the cadence within the active window.
    var intervalMinutes: Int
    /// Active window start, minutes from midnight (e.g. 9 * 60 = 540).
    var activeStartMinute: Int
    /// Active window end, minutes from midnight (e.g. 18 * 60 = 1080).
    var activeEndMinute: Int
    /// Calendar weekday numbers that are active (1 = Sun … 7 = Sat).
    var weekdays: Set<Int>

    static let allWeekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    static let workdays: Set<Int> = [2, 3, 4, 5, 6]

    /// A sensible office-friendly default: every 50 min, 09–18, weekdays.
    static let officeDefault = Schedule(intervalMinutes: 50,
                                        activeStartMinute: 9 * 60,
                                        activeEndMinute: 18 * 60,
                                        weekdays: workdays)

    /// A neutral default for a plain reminder: every hour, 09–22, every day.
    static let plainDefault = Schedule(intervalMinutes: 60,
                                       activeStartMinute: 9 * 60,
                                       activeEndMinute: 22 * 60,
                                       weekdays: allWeekdays)

    /// True when the window spans essentially the whole day.
    var isAllDay: Bool { activeStartMinute <= 0 && activeEndMinute >= 24 * 60 - 1 }
    var isEveryDay: Bool { weekdays == Self.allWeekdays }
    var isWorkdays: Bool { weekdays == Self.workdays }

    /// The next fire strictly after `reference`, or nil if the schedule can never fire.
    func nextFireDate(after reference: Date, calendar: Calendar = .current) -> Date? {
        guard intervalMinutes > 0, !weekdays.isEmpty else { return nil }
        let start = max(0, activeStartMinute)
        let end = min(24 * 60 - 1, activeEndMinute)
        guard end >= start else { return nil }

        let refDay = calendar.startOfDay(for: reference)
        // Look ahead up to 8 days so a single active weekday still resolves.
        for dayOffset in 0...8 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: refDay) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            guard weekdays.contains(weekday) else { continue }

            var minute = start
            while minute <= end {
                if let candidate = calendar.date(byAdding: .minute, value: minute, to: day),
                   candidate > reference {
                    return candidate
                }
                minute += intervalMinutes
            }
        }
        return nil
    }
}
