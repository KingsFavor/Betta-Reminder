import SwiftUI
import AppKit

/// The menu-bar popover: the next countdown at a glance, plus a quick on/off for every
/// reminder — the common check-in that doesn't need the whole window.
struct MenuBarContent: View {
    @Environment(ReminderStore.self) private var store
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openWindow) private var openWindow
    private var t: Theme { Theme(scheme: scheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Next up — recomputed each second so it rolls over while the popover is open.
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                if let up = store.nextUp {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(text: "다음 알림까지")
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            CountdownText(target: up.date,
                                          font: .system(size: 26, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textPrimary)
                            Spacer()
                            Text(up.reminder.resolvedTitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(t.textSecondary)
                                .lineLimit(1)
                        }
                    }
                } else {
                    Text(store.reminders.isEmpty ? "알림이 없어요" : "켜진 알림이 없어요")
                        .font(.system(size: 12))
                        .foregroundStyle(t.textSecondary)
                }
            }
            .padding(12)

            Divider()

            // Reminder toggles
            if !store.reminders.isEmpty {
                VStack(spacing: 2) {
                    ForEach(store.reminders) { reminder in
                        row(reminder)
                    }
                }
                .padding(.vertical, 6)
                Divider()
            }

            // Actions
            VStack(spacing: 2) {
                menuButton("Betta 열기", "macwindow") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: MainWindow.id)
                }
                menuButton("종료", "power") { NSApp.terminate(nil) }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 260)
    }

    private func row(_ reminder: Reminder) -> some View {
        let binding = Binding(get: { reminder.isEnabled },
                              set: { store.setEnabled(reminder, $0) })
        return HStack(spacing: 8) {
            Image(systemName: reminder.template.symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(reminder.isEnabled ? t.accent : t.textMuted)
                .frame(width: 18)
            Text(reminder.resolvedTitle)
                .font(.system(size: 13))
                .foregroundStyle(reminder.isEnabled ? t.textPrimary : t.textMuted)
                .lineLimit(1)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(t.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }

    private func menuButton(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 12)).frame(width: 18)
                Text(title).font(.system(size: 13))
                Spacer()
            }
            .foregroundStyle(t.textPrimary)
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}
