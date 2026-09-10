import SwiftUI

/// One source of truth for color and shape, resolved per color scheme.
///
/// Neutral ink-on-paper surfaces (echoing the monochrome betta wordmark), with a
/// single restrained **betta-coral** accent used *sparingly* — only where the eye
/// must land: the live toggle, the next-reminder highlight, the primary action.
/// Everything else stays quiet so the accent keeps its meaning.
struct Theme {
    let scheme: ColorScheme
    var isDark: Bool { scheme == .dark }

    // MARK: Surfaces
    /// App window background.
    var window: Color { isDark ? Color(hex: "#1C1C1E") : Color(hex: "#FBFAF8") }
    /// Raised card / row.
    var card: Color { isDark ? Color(hex: "#2A2A2C") : Color(hex: "#FFFFFF") }
    /// Recessed / disabled card.
    var cardMuted: Color { isDark ? Color(hex: "#222224") : Color(hex: "#F4F3F0") }
    /// Small control panels (segmented control, chips, steppers).
    var panel: Color { isDark ? Color(hex: "#2A2A2C") : Color(hex: "#F1F0ED") }
    var panelStrong: Color { isDark ? Color(hex: "#3A3A3D") : Color(hex: "#E8E7E3") }

    // MARK: Hairlines / borders
    var hairline: Color { isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.06) }
    var cardBorder: Color { isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.04) }
    var divider: Color { isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.05) }

    // MARK: Text
    var textPrimary: Color { isDark ? Color(hex: "#F4F4F2") : Color(hex: "#1B1B1A") }
    var textSecondary: Color { isDark ? Color(hex: "#9A9A95") : Color(hex: "#6A6A63") }
    var textMuted: Color { isDark ? Color(hex: "#75756F") : Color(hex: "#A6A5A1") }
    var textFaint: Color { isDark ? Color(hex: "#55555A") : Color(hex: "#C7C6C2") }

    // MARK: Accent (betta coral) — the one saturated color, used sparingly.
    var accent: Color { isDark ? Color(hex: "#E58370") : Color(hex: "#C8543F") }
    /// A very soft accent wash for selected backgrounds.
    var accentSoft: Color { accent.opacity(isDark ? 0.18 : 0.10) }
    var onAccent: Color { Color.white }

    // MARK: Shape metrics
    let windowRadius: CGFloat = 20
    let cardRadius: CGFloat = 14
    let chipRadius: CGFloat = 7
    let controlRadius: CGFloat = 10
    /// Popup toast corner.
    let popupRadius: CGFloat = 18
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme(scheme: .light)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    /// Injects a `Theme` resolved from the current color scheme.
    func provideTheme(_ scheme: ColorScheme) -> some View {
        environment(\.theme, Theme(scheme: scheme))
    }
}
