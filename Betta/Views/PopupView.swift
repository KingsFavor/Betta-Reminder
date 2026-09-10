import SwiftUI

/// The content shown inside a floating popup panel. Two layouts share one shell:
/// a plain text nudge, and the rich office-stretch layout that shows an actual
/// stretch illustration and a rotating guided pose — the template's reason to exist.
struct PopupView: View {
    let reminder: Reminder
    let onClose: () -> Void

    @Environment(\.colorScheme) private var scheme
    private var t: Theme { Theme(scheme: scheme) }

    var body: some View {
        Group {
            if reminder.template == .officeStretch {
                stretch
            } else {
                plain
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: t.popupRadius, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: t.popupRadius, style: .continuous)
                        .strokeBorder(t.hairline, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: t.popupRadius, style: .continuous))
    }

    // MARK: Plain

    private var plain: some View {
        HStack(alignment: .top, spacing: 12) {
            iconBadge(symbol: reminder.template.symbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.resolvedTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(t.textPrimary)
                if !reminder.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(reminder.message)
                        .font(.system(size: 13))
                        .foregroundStyle(t.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            closeButton
        }
    }

    // MARK: Rich — office stretch

    /// The whole routine shown at once: one large illustration, then every stretch as
    /// a numbered row. The popup is free to grow tall — the panel sizes to fit.
    private var stretch: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "figure.cooldown")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.accent)
                Text(reminder.resolvedTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.textPrimary)
                Spacer(minLength: 4)
                closeButton
            }

            Image("StretchPose")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 176)
                .background(t.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(spacing: 0) {
                ForEach(Array(StretchPose.all.enumerated()), id: \.element.id) { index, p in
                    poseRow(number: index + 1, pose: p)
                    if index < StretchPose.all.count - 1 {
                        Divider().overlay(t.divider)
                    }
                }
            }
            .padding(.vertical, 2)
            .background(t.cardMuted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func poseRow(number: Int, pose: StretchPose) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(t.onAccent)
                .frame(width: 22, height: 22)
                .background(t.accent, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(pose.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(t.textPrimary)
                Text(pose.cue)
                    .font(.system(size: 12))
                    .foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            Text("\(pose.holdSeconds)초")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.accent)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: Pieces

    private func iconBadge(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(t.accent)
            .frame(width: 34, height: 34)
            .background(t.accentSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(t.textMuted)
                .frame(width: 22, height: 22)
                .background(t.panel, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
