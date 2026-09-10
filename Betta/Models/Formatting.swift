import Foundation

/// Small, shared formatting helpers so schedule text reads the same everywhere.
enum Fmt {
    /// Korean single-letter weekday symbols, indexed by `Calendar` weekday (1 = Sun).
    static let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    static func weekdaySymbol(_ weekday: Int) -> String {
        weekdaySymbols[(weekday - 1 + 7) % 7]
    }

    /// "09:00" from minutes-since-midnight.
    static func clock(_ minute: Int) -> String {
        let h = (minute / 60) % 24
        let m = minute % 60
        return String(format: "%02d:%02d", h, m)
    }

    /// A compact interval label: "50분마다", "1시간마다", "1시간 30분마다".
    static func interval(_ minutes: Int) -> String {
        if minutes % 60 == 0 { return "\(minutes / 60)시간마다" }
        if minutes < 60 { return "\(minutes)분마다" }
        return "\(minutes / 60)시간 \(minutes % 60)분마다"
    }

    /// mm:ss (or h:mm:ss) countdown from a duration in seconds.
    static func countdown(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}

extension Schedule {
    /// A one-line human summary: "50분마다 · 09–18 · 평일".
    var summary: String {
        var parts = [Fmt.interval(intervalMinutes)]
        if !isAllDay {
            let start = Fmt.clock(activeStartMinute).prefix(5)
            let end = Fmt.clock(activeEndMinute).prefix(5)
            parts.append("\(start)–\(end)")
        }
        parts.append(weekdayLabel)
        return parts.joined(separator: " · ")
    }

    /// "매일", "평일", "주말", or "월·수·금".
    var weekdayLabel: String {
        if isEveryDay { return "매일" }
        if isWorkdays { return "평일" }
        if weekdays == [1, 7] { return "주말" }
        let ordered = [2, 3, 4, 5, 6, 7, 1].filter { weekdays.contains($0) }
        return ordered.map { Fmt.weekdaySymbol($0) }.joined(separator: "·")
    }
}
