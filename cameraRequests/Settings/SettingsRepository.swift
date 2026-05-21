import Foundation
import FirebaseFirestore

@MainActor
final class SettingsRepository {
    static let shared = SettingsRepository()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private init() {}

    func startListening(uid: String, onChange: @escaping (NotificationSettings) -> Void) {
        stop()
        listener = db.collection("users").document(uid)
            .addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data() else {
                    onChange(.default)
                    return
                }
                let raw = data["notificationSettings"] as? [String: Any] ?? [:]
                onChange(Self.decode(raw))
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func save(uid: String, settings: NotificationSettings) async throws {
        try await db.collection("users").document(uid).setData(
            [
                "notificationSettings": Self.encode(settings)
            ],
            merge: true,
        )
    }

    // MARK: - Encoding

    private static func decode(_ raw: [String: Any]) -> NotificationSettings {
        var s = NotificationSettings.default
        if let v = raw["newLeadEnabled"] as? Bool { s.newLeadEnabled = v }
        if let v = raw["remindersEnabled"] as? Bool { s.remindersEnabled = v }
        if let v = raw["quietHoursEnabled"] as? Bool { s.quietHoursEnabled = v }
        if let v = raw["quietStartHour"] as? Int { s.quietStartHour = clampHour(v) }
        if let v = raw["quietEndHour"] as? Int { s.quietEndHour = clampHour(v) }
        if let v = raw["timezone"] as? String, !v.isEmpty { s.timezone = v }
        if let v = raw["soundEnabled"] as? Bool { s.soundEnabled = v }
        return s
    }

    private static func encode(_ s: NotificationSettings) -> [String: Any] {
        return [
            "newLeadEnabled": s.newLeadEnabled,
            "remindersEnabled": s.remindersEnabled,
            "quietHoursEnabled": s.quietHoursEnabled,
            "quietStartHour": clampHour(s.quietStartHour),
            "quietEndHour": clampHour(s.quietEndHour),
            "timezone": s.timezone,
            "soundEnabled": s.soundEnabled,
        ]
    }

    private static func clampHour(_ v: Int) -> Int {
        max(0, min(23, v))
    }
}
