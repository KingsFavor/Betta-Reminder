import SwiftUI

/// One reminder in the list: identity + schedule at a glance, a **테스트** button to
/// preview the popup, and an on/off toggle. The whole row is tappable to edit.
struct ReminderRowView: View {
    let reminder: Reminder
    let onEdit: () -> Void
    let onTest: () -> Void

    @Environment(\.theme) private var t
    @Environment(ReminderStore.self) private var store

    @State private var testedFlash = false

    private var enabledBinding: Binding<Bool> {
        Binding(get: { reminder.isEnabled },
                set: { store.setEnabled(reminder, $0) })
    }

    var body: some View {
        HStack(spacing: 12) {
            // Template glyph
            Image(systemName: reminder.template.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(reminder.isEnabled ? t.accent : t.textMuted)
                .frame(width: 36, height: 36)
                .background(reminder.isEnabled ? t.accentSoft : t.panel,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Identity + schedule
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.resolvedTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(reminder.isEnabled ? t.textPrimary : t.textMuted)
                    .lineLimit(1)
                Text(reminder.schedule.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(t.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Test — preview the popup exactly as it will appear
            Button(action: {
                onTest()
                withAnimation(.easeOut(duration: 0.15)) { testedFlash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.2)) { testedFlash = false }
                }
            }) {
                Image(systemName: testedFlash ? "checkmark" : "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(testedFlash ? t.accent : t.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(t.panel, in: Circle())
            }
            .buttonStyle(.plain)
            .help("테스트 — 지금 팝업 미리보기")

            Toggle("", isOn: enabledBinding)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(t.accent)
        }
        .padding(12)
        .card()
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}
