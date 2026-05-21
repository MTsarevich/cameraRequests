import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

@MainActor
final class PushService {
    static let shared = PushService()
    private let db = Firestore.firestore()
    private var currentToken: String?

    private init() {}

    // Ask the user for notification permission and trigger APNs registration.
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("[PushService] auth error:", error)
        }
    }

    // Sets the app icon badge to the count of unhandled (new) leads.
    func setBadge(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(max(0, count)) { error in
            if let error { print("[PushService] setBadge error:", error) }
        }
    }

    // Persist a new FCM token in the current user's fcmTokens array (idempotent).
    func registerToken(_ token: String) async {
        currentToken = token
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(uid).setData(
                [
                    "fcmTokens": FieldValue.arrayUnion([token])
                ],
                merge: true,
            )
        } catch {
            print("[PushService] failed to register token:", error)
        }
    }

    // Remove this device's token on sign-out.
    func unregisterCurrentToken() async {
        guard let uid = Auth.auth().currentUser?.uid,
              let token = currentToken else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "fcmTokens": FieldValue.arrayRemove([token])
            ])
        } catch {
            print("[PushService] failed to unregister token:", error)
        }
    }

    // Re-register on app start if we already have a cached token (e.g. user signed in last session).
    func refreshTokenIfNeeded() async {
        do {
            let token = try await Messaging.messaging().token()
            await registerToken(token)
        } catch {
            print("[PushService] failed to fetch FCM token:", error)
        }
    }
}
