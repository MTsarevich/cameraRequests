import Foundation
import LocalAuthentication

enum BiometricAuth {

    // Prompts Face ID / Touch ID, falling back to the device passcode.
    // Returns true only when the user successfully authenticates.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print("[BiometricAuth] policy unavailable:", error?.localizedDescription ?? "")
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason,
            )
        } catch {
            print("[BiometricAuth] auth failed:", error.localizedDescription)
            return false
        }
    }
}
