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
/// cue, and how long to hold. The poses form an ordered routine (step 1…N); the
/// popup advances one step each time it fires, and shows the position in the routine
/// as a dedicated step indicator (not a text list).
struct StretchPose: Identifiable, Equatable {
    let id: Int
    let name: String
    let cue: String
    let holdSeconds: Int

    /// The ordered stretch routine the office-stretch template steps through.
    static let all: [StretchPose] = [
        StretchPose(id: 0, name: "목 뒤 근육 늘리기", cue: "깍지 낀 손을 뒤통수에 얹고 턱을 가슴 쪽으로", holdSeconds: 20),
        StretchPose(id: 1, name: "턱 당기기", cue: "턱을 뒤로 당겨 이중턱을 만들 듯 5초씩", holdSeconds: 15),
        StretchPose(id: 2, name: "옆 목 스트레칭", cue: "한 손으로 반대쪽 머리를 어깨 쪽으로 당기며", holdSeconds: 20),
        StretchPose(id: 3, name: "어깨 으쓱 스트레칭", cue: "어깨를 귀까지 올렸다가 툭 내려놓기", holdSeconds: 15),
        StretchPose(id: 4, name: "가슴 펴기 스트레칭", cue: "손을 등 뒤로 깍지 끼고 가슴을 활짝 열며", holdSeconds: 20),
    ]

    static var count: Int { all.count }

    static func pose(at index: Int) -> StretchPose {
        all[((index % all.count) + all.count) % all.count]
    }

    /// 1-based step number within the routine for a given rotation cursor.
    static func step(at index: Int) -> Int {
        ((index % all.count) + all.count) % all.count + 1
    }
}
