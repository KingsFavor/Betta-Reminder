import SwiftUI

/// A live-updating countdown to `target`, ticking once per second only while visible
/// (TimelineView drives it, so there's no timer running when the window is closed).
struct CountdownText: View {
    let target: Date
    var font: Font = .system(size: 34, weight: .semibold, design: .rounded)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int(target.timeIntervalSince(context.date).rounded(.up))
            Text(Fmt.countdown(remaining))
                .font(font)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }
}

/// A quiet section label (uppercase-ish small caps feel via tracking).
struct SectionLabel: View {
    let text: String
    @Environment(\.theme) private var t
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(t.textMuted)
    }
}

/// A small pill used for schedule facets in rows.
struct Chip: View {
    let text: String
    var accent: Bool = false
    @Environment(\.theme) private var t
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(accent ? t.accent : t.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(accent ? t.accentSoft : t.panel,
                        in: RoundedRectangle(cornerRadius: t.chipRadius, style: .continuous))
    }
}

/// A hairline-bordered card surface.
struct CardBackground: ViewModifier {
    @Environment(\.theme) private var t
    func body(content: Content) -> some View {
        content
            .background(t.card, in: RoundedRectangle(cornerRadius: t.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: t.cardRadius, style: .continuous)
                    .strokeBorder(t.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
