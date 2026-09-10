import SwiftUI

/// Settings: just the few things that matter — how long a popup lingers, whether Betta
/// starts with the Mac, and updates. Kept short on purpose.
struct SettingsView: View {
    @Environment(ReminderStore.self) private var store
    @Environment(UpdateChecker.self) private var updates
    @Environment(\.colorScheme) private var scheme
    private var t: Theme { Theme(scheme: scheme) }

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        @Bindable var store = store
        Form {
            Section("팝업") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("표시 시간")
                        Spacer()
                        Text("\(Int(store.popupDuration))초")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $store.popupDuration, in: 5...60, step: 1)
                        .tint(t.accent)
                    Text("팝업이 스스로 사라지기까지의 시간")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("일반") {
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
        .frame(width: 380, height: 420)
        .tint(t.accent)
    }
}
