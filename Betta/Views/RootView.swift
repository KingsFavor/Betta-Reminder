import SwiftUI

/// The main window: what's coming next (with a live countdown), then every reminder
/// as a togglable, testable row. Opened from the Dock icon.
struct RootView: View {
    @Environment(ReminderStore.self) private var store
    @Environment(UpdateChecker.self) private var updates
    @Environment(\.colorScheme) private var scheme

    @State private var route: EditorRoute?

    private var t: Theme { Theme(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            header
            if updates.isBannerVisible { updateBanner }
            ScrollView {
                VStack(spacing: 14) {
                    nextUp
                    list
                }
                .padding(16)
            }
        }
        .frame(minWidth: 400, minHeight: 520)
        .background(t.window)
        .provideTheme(scheme)
        .sheet(item: $route) { item in
            switch item {
            case .new:
                TemplateGalleryView(onFinish: { route = nil }).provideTheme(scheme)
            case .edit(let reminder):
                NavigationStack {
                    ReminderEditorView(initial: reminder, isNew: false)
                        .navigationTitle("알림 편집")
                }
                .provideTheme(scheme)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Image("BettaLogo")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .foregroundStyle(t.textPrimary)
            Text("Betta")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(t.textPrimary)
            Spacer()
            // Always-on-top pin
            Button { store.alwaysOnTop.toggle() } label: {
                Image(systemName: store.alwaysOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(store.alwaysOnTop ? t.accent : t.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(store.alwaysOnTop ? t.accentSoft : Color.clear,
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(store.alwaysOnTop ? "항상 위에 고정됨" : "항상 위에 고정")
            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(t.textSecondary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            Button { route = .new } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(t.onAccent)
                    .frame(width: 30, height: 30)
                    .background(t.accent, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("새 알림")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(t.window)
        .overlay(alignment: .bottom) { Rectangle().fill(t.divider).frame(height: 1) }
    }

    // MARK: Next up hero

    // Re-evaluated each second so the "next" target rolls over on its own once a
    // fire time passes — even for plain reminders that don't mutate the store.
    private var nextUp: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in nextUpBody }
    }

    @ViewBuilder
    private var nextUpBody: some View {
        if let up = store.nextUp {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "다음 알림까지")
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    CountdownText(target: up.date)
                        .foregroundStyle(t.textPrimary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(up.reminder.resolvedTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(t.textPrimary)
                            .lineLimit(1)
                        Text(up.date, format: .dateTime.hour().minute())
                            .font(.system(size: 12))
                            .foregroundStyle(t.textSecondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(t.accentSoft, in: RoundedRectangle(cornerRadius: t.cardRadius, style: .continuous))
        } else {
            HStack(spacing: 10) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(t.textMuted)
                Text(store.reminders.isEmpty ? "아직 알림이 없어요" : "켜져 있는 알림이 없어요")
                    .font(.system(size: 13))
                    .foregroundStyle(t.textSecondary)
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(t.cardMuted, in: RoundedRectangle(cornerRadius: t.cardRadius, style: .continuous))
        }
    }

    // MARK: List

    @ViewBuilder
    private var list: some View {
        if store.reminders.isEmpty {
            emptyState
        } else {
            VStack(spacing: 10) {
                ForEach(store.reminders) { reminder in
                    ReminderRowView(
                        reminder: reminder,
                        onEdit: { route = .edit(reminder) },
                        onTest: {
                            PopupPresenter.shared.present(reminder,
                                                          duration: Double(reminder.popupDurationSeconds),
                                                          corner: store.popupCorner)
                        }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image("BettaLogo")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .foregroundStyle(t.textFaint)
            Button { route = .new } label: {
                Label("첫 알림 만들기", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.onAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(t.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: Update banner

    private var updateBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(t.accent)
            Text("새 버전 \(updates.latestVersion ?? "") 사용 가능")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(t.textPrimary)
            Spacer()
            Button("명령 복사") { updates.copyUpdateCommand() }
                .font(.system(size: 12, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(t.accent)
            Button { updates.dismissBanner() } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(t.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(t.accentSoft)
    }
}

/// Sheet routing for the main window.
enum EditorRoute: Identifiable {
    case new
    case edit(Reminder)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let r): return r.id.uuidString
        }
    }
}
