import Foundation

enum LeadStatus: String, Codable, CaseIterable, Identifiable {
    case new = "new"
    case inProgress = "in_progress"
    case closed = "closed"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .new: return "Новые"
        case .inProgress: return "В работе"
        case .closed: return "Закрытые"
        }
    }

    var shortLabel: String {
        switch self {
        case .new: return "Новая"
        case .inProgress: return "В работе"
        case .closed: return "Закрыта"
        }
    }
}
