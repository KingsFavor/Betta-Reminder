import SwiftUI

/// A reminder's kind. `plain` is pure text; a template adds a *special* presentation
/// (the office-stretch one shows an actual stretching illustration and rotates through
/// guided poses) — the point of a template is that it does more than a text line could.
enum ReminderTemplate: String, Codable, CaseIterable, Identifiable {
    case plain
    case officeStretch

    var id: String { rawValue }

    /// Whether the popup renders the rich (image-bearing) layout instead of plain text.
    var isRich: Bool { self != .plain }

    var displayName: String {
        switch self {
        case .plain:         return "일반 알림"
        case .officeStretch: return "사무직 스트레칭"
        }
    }

    /// SF Symbol used in the template gallery and reminder rows.
    var symbol: String {
        switch self {
        case .plain:         return "bell"
        case .officeStretch: return "figure.cooldown"
        }
    }

    /// The seed applied when a user picks this template in the editor.
    var seedTitle: String {
        switch self {
        case .plain:         return ""
        case .officeStretch: return "스트레칭 시간"
        }
    }

    var seedSchedule: Schedule {
        switch self {
        case .plain:         return .plainDefault
        case .officeStretch: return .officeDefault
        }
    }
}

/// One guided stretch shown in the office-stretch popup: a short name, a one-line
/// cue, and how long to hold. The illustration is the shared `StretchPose` asset;
/// the pose text rotates so each nudge feels fresh rather than repetitive.
struct StretchPose: Identifiable, Equatable {
    let id: Int
    let name: String
    let cue: String
    let holdSeconds: Int

    /// The rotation of poses the office-stretch template cycles through.
    static let all: [StretchPose] = [
        StretchPose(id: 0, name: "목 좌우로 기울이기", cue: "귀를 어깨 쪽으로 천천히", holdSeconds: 20),
        StretchPose(id: 1, name: "어깨 으쓱 내리기", cue: "귀에서 어깨를 멀리 떨어뜨리며", holdSeconds: 15),
        StretchPose(id: 2, name: "가슴 열기", cue: "손깍지 끼고 뒤로, 가슴을 펴며", holdSeconds: 20),
        StretchPose(id: 3, name: "손목 돌리기", cue: "양쪽으로 천천히 크게", holdSeconds: 15),
        StretchPose(id: 4, name: "허리 비틀기", cue: "의자에 앉아 상체만 좌우로", holdSeconds: 20),
        StretchPose(id: 5, name: "눈 멀리 보기", cue: "20초간 6m 밖 먼 곳을 응시", holdSeconds: 20),
    ]

    static func pose(at index: Int) -> StretchPose {
        all[((index % all.count) + all.count) % all.count]
    }
}
