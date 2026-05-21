import Foundation
import Observation
import FirebaseAuth

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    private var handle: AuthStateDidChangeListenerHandle?

    var isSignedIn: Bool { currentUser != nil }
    var userEmail: String? { currentUser?.email }
    var uid: String? { currentUser?.uid }

    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
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
