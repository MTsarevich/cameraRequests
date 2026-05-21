import Foundation
import FirebaseFirestore

struct Lead: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var phone: String
    var message: String?
    var source: String
    var pageUrl: String?
    var status: LeadStatus
    var createdAt: Date?
    var updatedAt: Date?
    var assignedTo: String?
    var lastRemindedAt: Date?
    var reminderCount: Int?

    // Used by the client-side search filter. Concatenates every text field a user might type.
    var searchableHaystack: String {
        [name, phone, message ?? "", pageUrl ?? "", source]
            .joined(separator: " ")
            .lowercased()
    }

    static func == (lhs: Lead, rhs: Lead) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.phone == rhs.phone
            && lhs.message == rhs.message
            && lhs.status == rhs.status
            && lhs.createdAt == rhs.createdAt
            && lhs.updatedAt == rhs.updatedAt
    }
}
