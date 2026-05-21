import SwiftUI
import FirebaseCore

@main
struct cameraRequestsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // Must be configured BEFORE anything touches Auth/Firestore/Messaging.
        // Doing it here (rather than in AppDelegate) avoids a race with
        // singletons that may be initialised during SwiftUI scene setup.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(DeepLinkRouter.shared)
                .environment(AuthService.shared)
        }
    }
}
