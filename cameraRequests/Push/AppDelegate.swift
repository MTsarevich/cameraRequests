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

final class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // FirebaseApp.configure() is called from cameraRequestsApp.init() — it must run
        // before any singleton (AuthService, LeadsRepository) touches Firebase APIs.

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        application.registerForRemoteNotifications()
        return true
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

    // Handle tap on notification: capture leadId for deep-link.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let leadId = userInfo["leadId"] as? String {
            await MainActor.run {
                DeepLinkRouter.shared.pendingLeadId = leadId
            }
        }
    }
}
