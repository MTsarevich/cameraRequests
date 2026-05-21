import Foundation
import Observation
import FirebaseAuth

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    // False until Firebase Auth reports its first state. Lets the UI show a
    // launch screen instead of briefly flashing the sign-in screen.
    private(set) var isResolved = false
    private var handle: AuthStateDidChangeListenerHandle?

    var isSignedIn: Bool { currentUser != nil }
    var userEmail: String? { currentUser?.email }
    var uid: String? { currentUser?.uid }

    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isResolved = true
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.currentUser = result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
    }
}
