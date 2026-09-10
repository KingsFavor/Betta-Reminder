import SwiftUI

/// The recurrence editor: interval, active window, and weekdays — the three facets of
/// `Schedule`. Everything is one or two taps: preset chips for common intervals, a
/// clock picker for the window, and day circles. No free-text, no manual cron.
struct SchedulePickerView: View {
    @Binding var schedule: Schedule
    @Environment(\.theme) private var t

    private let intervalPresets = [15, 30, 45, 50, 60, 90, 120]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            interval
            activeWindow
            weekdays
        }
    }

    // MARK: Interval

    private var interval: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(text: "반복 간격")
                Spacer()
                Text(Fmt.interval(schedule.intervalMinutes))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.accent)
            }
            // Preset chips
            HStack(spacing: 6) {
                ForEach(intervalPresets, id: \.self) { m in
                    let on = schedule.intervalMinutes == m
                    Button {
                        schedule.intervalMinutes = m
                    } label: {
                        Text(m % 60 == 0 ? "\(m/60)시간" : "\(m)분")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(on ? t.onAccent : t.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(on ? t.accent : t.panel,
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            // Fine control
            Stepper(value: $schedule.intervalMinutes, in: 5...600, step: 5) {
                Text("직접 조정 · 5분 단위")
                    .font(.system(size: 12))
                    .foregroundStyle(t.textMuted)
            }
        }
    }

    // MARK: Active window

    private var isAllDay: Binding<Bool> {
        Binding(
            get: { schedule.isAllDay },
            set: { all in
                if all {
                    schedule.activeStartMinute = 0
                    schedule.activeEndMinute = 24 * 60 - 1
                } else {
                    schedule.activeStartMinute = 9 * 60
                    schedule.activeEndMinute = 18 * 60
                }
            })
    }

    private func minuteBinding(_ keyPath: WritableKeyPath<Schedule, Int>) -> Binding<Date> {
        Binding(
            get: {
                let cal = Calendar.current
                let m = schedule[keyPath: keyPath]
                return cal.date(bySettingHour: (m / 60) % 24, minute: m % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                schedule[keyPath: keyPath] = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            })
    }

    private var activeWindow: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(text: "활동 시간대")
                Spacer()
                Toggle("종일", isOn: isAllDay)
                    .toggleStyle(.button)
                    .font(.system(size: 11, weight: .medium))
                    .tint(t.accent)
            }
            if !schedule.isAllDay {
                HStack(spacing: 10) {
                    DatePicker("", selection: minuteBinding(\.activeStartMinute), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(t.textMuted)
                    DatePicker("", selection: minuteBinding(\.activeEndMinute), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Spacer()
                }
            }
        }
    }

    // MARK: Weekdays

    private var weekdays: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(text: "요일")
                Spacer()
                HStack(spacing: 6) {
                    quickDay("매일", Schedule.allWeekdays)
                    quickDay("평일", Schedule.workdays)
                    quickDay("주말", [1, 7])
                }
            }
            HStack(spacing: 6) {
                // Display Mon→Sun for a work-week feel.
                ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { wd in
                    let on = schedule.weekdays.contains(wd)
                    Button {
                        if on { schedule.weekdays.remove(wd) } else { schedule.weekdays.insert(wd) }
                    } label: {
                        Text(Fmt.weekdaySymbol(wd))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(on ? t.onAccent : t.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(on ? t.accent : t.panel,
                                        in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickDay(_ label: String, _ set: Set<Int>) -> some View {
        let on = schedule.weekdays == set
        return Button { schedule.weekdays = set } label: {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(on ? t.accent : t.textMuted)
        }
        .buttonStyle(.plain)
    }
}
