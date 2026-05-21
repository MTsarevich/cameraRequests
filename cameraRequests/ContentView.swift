import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        Group {
            if auth.isSignedIn {
                LeadsListView()
                    .task {
                        await PushService.shared.requestAuthorization()
                        await PushService.shared.refreshTokenIfNeeded()
                    }
            } else {
                SignInView()
            }
        }
    }
}
