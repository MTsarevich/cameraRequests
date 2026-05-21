import Foundation
import FirebaseFirestore

@MainActor
final class LeadsRepository {
    static let shared = LeadsRepository()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private init() {}

    func startListening(onChange: @escaping ([Lead]) -> Void) {
        stop()
        listener = db.collection("leads")
            .order(by: "createdAt", descending: true)
            .limit(to: 500)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    if let error { print("[LeadsRepository] listen error:", error) }
                    return
                }
                let leads: [Lead] = snapshot.documents.compactMap { doc in
                    do {
                        return try doc.data(as: Lead.self)
                    } catch {
                        print("[LeadsRepository] decode error for", doc.documentID, error)
                        return nil
                    }
                }
                onChange(leads)
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func updateStatus(leadId: String, status: LeadStatus) async throws {
        try await db.collection("leads").document(leadId).updateData([
            "status": status.rawValue,
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }
}
