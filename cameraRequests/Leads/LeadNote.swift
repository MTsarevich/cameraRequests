import Foundation
import FirebaseFirestore

// An internal team comment attached to a lead (leads/{leadId}/notes/{noteId}).
struct LeadNote: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var authorName: String
    var createdAt: Date?
}
