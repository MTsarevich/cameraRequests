import UIKit
import Combine
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// Tracks the latest deep-link target (leadId). LeadsListView observes this and presents the sheet.
@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    @Published var pendingLeadId: String?
    private init() {}
}

// Notification category / action identifiers for the "take in progress" push button.
enum PushAction {
    static let category = "NEW_LEAD"
    static let takeInProgress = "TAKE_IN_PROGRESS"
}

final class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // FirebaseApp.configure() is called from cameraRequestsApp.init() — it must run
        // before any singleton (AuthService, LeadsRepository) touches Firebase APIs.

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()

        application.registerForRemoteNotifications()
        return true
    }

    // Defines the "Взять в работу" button shown on lead notifications.
    // .foreground brings the app forward so a Face ID check can run.
    private func registerNotificationCategories() {
        let takeAction = UNNotificationAction(
            identifier: PushAction.takeInProgress,
            title: "Взять в работу",
            options: [.foreground],
        )
        let category = UNNotificationCategory(
            identifier: PushAction.category,
            actions: [takeAction],
            intentIdentifiers: [],
            options: [],
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - APNs token plumbing

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Push] APNs registration failed:", error)
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { @MainActor in
            await PushService.shared.registerToken(fcmToken)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show banner & sound when push arrives while app is foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    // Handles notification taps and the "Взять в работу" action button.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        guard let leadId = userInfo["leadId"] as? String else { return }

        if response.actionIdentifier == PushAction.takeInProgress {
            // The push button requires Face ID / passcode before changing the status.
            let confirmed = await BiometricAuth.authenticate(
                reason: "Подтвердите, чтобы взять заявку в работу",
            )
            if confirmed {
                try? await LeadsRepository.shared.updateStatus(leadId: leadId, status: .inProgress)
            }
        }

        // Open the lead either way so the user sees the result.
        await MainActor.run {
            DeepLinkRouter.shared.pendingLeadId = leadId
        }
    }
}
