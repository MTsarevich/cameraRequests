import Foundation
import Network
import Observation

// Tracks connectivity so the UI can show an offline banner.
@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            guard let self else { return }
            Task { @MainActor in
                self.isOnline = online
            }
        }
        monitor.start(queue: queue)
    }
}
