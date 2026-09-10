import SwiftUI

/// Settings: where popups appear, whether the window floats, and updates. Popup
/// *duration* is per-reminder now (set in each reminder's editor), so it isn't here.
struct SettingsView: View {
    @Environment(ReminderStore.self) private var store
    @Environment(UpdateChecker.self) private var updates
    @Environment(\.colorScheme) private var scheme
    private var t: Theme { Theme(scheme: scheme) }

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        @Bindable var store = store
        Form {
            Section("알림 위치") {
                cornerPicker
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            }

            Section("일반") {
                Toggle("항상 위에 고정", isOn: $store.alwaysOnTop)
                Toggle("로그인 시 Betta 실행", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.isEnabled = newValue
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
            }

            Section("업데이트") {
                Toggle("자동으로 업데이트 확인", isOn: Binding(
                    get: { updates.autoCheckEnabled },
                    set: { updates.autoCheckEnabled = $0 }))
                HStack {
                    Text("현재 버전")
                    Spacer()
                    Text(updates.currentVersion).foregroundStyle(.secondary).monospacedDigit()
                }
                Button("지금 업데이트 확인") { updates.checkForUpdatesInteractive() }
                    .disabled(updates.isChecking)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 440)
        .tint(t.accent)
    }

    /// A little screen with a dot in the selected corner — pick where popups appear.
    private var cornerPicker: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(t.panel)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(t.hairline))
                ForEach(PopupCorner.allCases) { corner in
                    Circle()
                        .fill(store.popupCorner == corner ? t.accent : t.textFaint)
                        .frame(width: 9, height: 9)
                        .padding(7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: alignment(for: corner))
                }
            }
            .frame(width: 96, height: 62)

            // Corner buttons (2×2)
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    cornerButton(.topLeft)
                    cornerButton(.topRight)
                }
                GridRow {
                    cornerButton(.bottomLeft)
                    cornerButton(.bottomRight)
                }
            }
        }
    }

    private func cornerButton(_ corner: PopupCorner) -> some View {
        let on = store.popupCorner == corner
        return Button { store.popupCorner = corner } label: {
            HStack(spacing: 5) {
                Image(systemName: corner.symbol).font(.system(size: 10, weight: .bold))
                Text(corner.label).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(on ? t.onAccent : t.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(on ? t.accent : t.panel,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func alignment(for corner: PopupCorner) -> Alignment {
        switch corner {
        case .topLeft:     return .topLeading
        case .topRight:    return .topTrailing
        case .bottomLeft:  return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}
