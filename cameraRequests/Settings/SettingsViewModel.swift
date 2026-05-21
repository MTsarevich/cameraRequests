import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var settings = NotificationSettings.default
    var isLoading = true
    var errorMessage: String?

    private var saveTask: Task<Void, Never>?
    private let debounce: Duration = .milliseconds(500)

    func start(uid: String) {
        SettingsRepository.shared.startListening(uid: uid) { [weak self] s in
            Task { @MainActor in
                guard let self else { return }
                self.settings = s
                self.isLoading = false
            }
        }
    }

    func stop() {
        SettingsRepository.shared.stop()
        saveTask?.cancel()
    }

    // Debounced save: every mutation reschedules a 500ms timer; only the final value goes to Firestore.
    func scheduleSave(uid: String) {
        saveTask?.cancel()
        let snapshot = settings
        saveTask = Task {
            try? await Task.sleep(for: debounce)
            if Task.isCancelled { return }
            do {
                try await SettingsRepository.shared.save(uid: uid, settings: snapshot)
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription }
            }
        }
    }
}
