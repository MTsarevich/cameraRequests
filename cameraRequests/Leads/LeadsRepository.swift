import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class LeadsRepository {
    static let shared = LeadsRepository()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var notesListener: ListenerRegistration?

    private init() {}

    // MARK: - Leads

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
        var data: [String: Any] = [
            "status": status.rawValue,
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        switch status {
        case .inProgress:
            // Record who took the lead.
            if let user = Auth.auth().currentUser {
                data["assignedTo"] = user.uid
                data["assignedToName"] = user.email ?? "—"
            }
        case .new:
            // Reopened — clear the assignment.
            data["assignedTo"] = FieldValue.delete()
            data["assignedToName"] = FieldValue.delete()
        case .closed:
            break // keep whoever handled it
        }
        try await db.collection("leads").document(leadId).updateData(data)
    }

    // MARK: - Notes

    func startListeningNotes(leadId: String, onChange: @escaping ([LeadNote]) -> Void) {
        stopNotes()
        notesListener = db.collection("leads").document(leadId).collection("notes")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    if let error { print("[LeadsRepository] notes listen error:", error) }
                    return
                }
                let notes: [LeadNote] = snapshot.documents.compactMap { try? $0.data(as: LeadNote.self) }
                onChange(notes)
            }
    }

    func stopNotes() {
        notesListener?.remove()
        notesListener = nil
    }

    func addNote(leadId: String, text: String) async throws {
        let authorName = Auth.auth().currentUser?.email ?? "—"
        try await db.collection("leads").document(leadId).collection("notes").addDocument(data: [
            "text": text,
            "authorName": authorName,
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }
}
