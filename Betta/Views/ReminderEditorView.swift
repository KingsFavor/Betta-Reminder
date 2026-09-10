import SwiftUI

/// Create or edit a single reminder. Works on a local draft and commits on save, so
/// closing without saving changes nothing. A live **미리보기** shows the exact popup.
struct ReminderEditorView: View {
    @State private var draft: Reminder
    private let isNew: Bool
    /// When set, called instead of `dismiss` on finish — lets a pushed editor close
    /// the *entire* presenting sheet (not just pop back to the template gallery).
    private let onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var t
    @Environment(ReminderStore.self) private var store

    init(initial: Reminder, isNew: Bool, onComplete: (() -> Void)? = nil) {
        _draft = State(initialValue: initial)
        self.isNew = isNew
        self.onComplete = onComplete
    }

    private func finish() {
        if let onComplete { onComplete() } else { dismiss() }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                templateHeader
                content
                Divider().overlay(t.divider)
                SchedulePickerView(schedule: $draft.schedule)
                Divider().overlay(t.divider)
                durationSection
                if !isNew {
                    Button(role: .destructive) {
                        store.delete(draft)
                        finish()
                    } label: {
                        Label("이 알림 삭제", systemImage: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.red.opacity(0.9))
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .frame(width: 420, height: 620)
        .background(t.window)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Button {
                    PopupPresenter.shared.present(draft,
                                                  duration: Double(draft.popupDurationSeconds),
                                                  corner: store.popupCorner)
                } label: {
                    Label("미리보기", systemImage: "play.circle")
                }
                .help("현재 설정으로 팝업 미리보기")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isNew ? "추가" : "완료") { commit() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func commit() {
        if isNew { store.add(draft) } else { store.update(draft) }
        finish()
    }

    // MARK: Sections

    private var templateHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: draft.template.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(t.accent)
                .frame(width: 44, height: 44)
                .background(t.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.template.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(t.textPrimary)
                if draft.template.isRich {
                    Text("가이드 스트레칭 \(StretchPose.all.count)종을 순환")
                        .font(.system(size: 12))
                        .foregroundStyle(t.textSecondary)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            field(label: "이름") {
                TextField(draft.template.displayName, text: $draft.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
            }
            if draft.template == .plain {
                field(label: "메시지") {
                    TextField("팝업에 표시할 문구", text: $draft.message, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .lineLimit(1...4)
                }
            } else {
                // Rich template: show what the popup will carry instead of a text box.
                HStack(spacing: 12) {
                    Image("StretchPose")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("실제 스트레칭 이미지 + 자세 안내")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(t.textPrimary)
                        Text("목·어깨·손목·허리·눈 순으로 매번 다르게")
                            .font(.system(size: 11))
                            .foregroundStyle(t.textSecondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(t.cardMuted, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    // MARK: Popup duration (per reminder)

    private let durationPresets: [(String, Int)] = [
        ("10초", 10), ("20초", 20), ("30초", 30), ("1분", 60), ("항상 유지", Reminder.keepAlways)
    ]

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(text: "표시 시간")
                Spacer()
                Text(draft.popupDurationSeconds == Reminder.keepAlways
                     ? "닫을 때까지"
                     : "\(draft.popupDurationSeconds)초 후 사라짐")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.accent)
            }
            HStack(spacing: 6) {
                ForEach(durationPresets, id: \.1) { label, value in
                    let on = draft.popupDurationSeconds == value
                    Button { draft.popupDurationSeconds = value } label: {
                        Text(label)
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
        }
    }

    private func field<Content: View>(label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label)
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(t.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
