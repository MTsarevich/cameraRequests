import SwiftUI

// Branded splash shown while Firebase Auth resolves the initial session —
// prevents the sign-in screen from flashing before the leads list appears.
struct LaunchView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "video.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Theme.brand, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Theme.brand.opacity(0.35), radius: 12, y: 6)

                Text("LinkUP")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                ProgressView()
                    .tint(Theme.brand)
                    .padding(.top, 6)
            }
        }
    }
}
