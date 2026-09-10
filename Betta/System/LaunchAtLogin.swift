import Foundation
import ServiceManagement

/// Thin wrapper over `SMAppService.mainApp` so the app can offer a "로그인 시 실행"
/// toggle. A reminder app is only useful if it's running, so this matters — but it
/// stays opt-in.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
                } else {
                    if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
                }
            } catch {
                // Non-fatal: the toggle simply reflects the real status on next read.
            }
        }
    }
}
