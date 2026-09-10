import SwiftUI

/// A compact, on-brand time selector (hour : minute) built from stepper units —
/// replaces the native `DatePicker` wheel so the picker matches the app's design.
/// Bound to minutes-from-midnight so it plugs straight into `Schedule`.
struct TimeSelector: View {
    @Binding var minutes: Int          // 0 … 1439
    var minuteStep: Int = 5
    @Environment(\.theme) private var t

    private var hour: Int { (minutes / 60) % 24 }
    private var minute: Int { minutes % 60 }

    var body: some View {
        HStack(spacing: 8) {
            unit(value: hour,
                 up: { setHour((hour + 1) % 24) },
                 down: { setHour((hour + 23) % 24) })
            Text(":")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(t.textMuted)
            unit(value: minute,
                 up: { setMinute((minute + minuteStep) % 60) },
                 down: { setMinute((minute - minuteStep + 60) % 60) })
        }
        .padding(6)
        .background(t.panel, in: RoundedRectangle(cornerRadius: t.controlRadius, style: .continuous))
    }

    private func setHour(_ h: Int) { minutes = h * 60 + minute }
    private func setMinute(_ m: Int) { minutes = hour * 60 + m }

    private func unit(value: Int, up: @escaping () -> Void, down: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(String(format: "%02d", value))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(t.textPrimary)
                .frame(minWidth: 30)
            VStack(spacing: 2) {
                chevron("chevron.up", action: up)
                chevron("chevron.down", action: down)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(t.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func chevron(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(t.textSecondary)
                .frame(width: 18, height: 13)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
