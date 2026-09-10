import SwiftUI

/// The "새 알림" entry point: pick a template, then land straight in the editor.
/// Templates are shown as cards so the special one (사무직 스트레칭) reads as a
/// richer choice, not just another list item.
struct TemplateGalleryView: View {
    /// Called after a new reminder is actually added, to close the whole sheet.
    var onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var t
    @State private var chosen: ReminderTemplate?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    card(.officeStretch,
                         subtitle: "목·어깨·손목·허리·눈 스트레칭을 이미지와 함께",
                         recommended: true)
                    card(.plain,
                         subtitle: "원하는 문구를 원하는 주기로",
                         recommended: false)
                }
                .padding(20)
            }
            .frame(width: 420, height: 360)
            .background(t.window)
            .navigationTitle("새 알림")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .navigationDestination(item: $chosen) { template in
                ReminderEditorView(initial: .seeded(from: template), isNew: true, onComplete: onFinish)
            }
        }
    }

    private func card(_ template: ReminderTemplate, subtitle: String, recommended: Bool) -> some View {
        Button { chosen = template } label: {
            HStack(spacing: 14) {
                Image(systemName: template.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(t.accent)
                    .frame(width: 52, height: 52)
                    .background(t.accentSoft, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(template.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(t.textPrimary)
                        if recommended {
                            Text("추천")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(t.onAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(t.accent, in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(t.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(t.textFaint)
            }
            .padding(14)
            .card()
        }
        .buttonStyle(.plain)
    }
}
