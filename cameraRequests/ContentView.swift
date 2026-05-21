import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        ZStack {
            if !auth.isResolved {
                LaunchView()
                    .transition(.opacity)
            } else if auth.isSignedIn {
                LeadsListView()
                    .transition(.opacity)
                    .task {
                        await PushService.shared.requestAuthorization()
                        await PushService.shared.refreshTokenIfNeeded()
                    }
            } else {
                SignInView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.isResolved)
        .animation(.easeInOut(duration: 0.25), value: auth.isSignedIn)
        .preferredColorScheme(.light)
        .tint(Theme.brand)
    }
}
