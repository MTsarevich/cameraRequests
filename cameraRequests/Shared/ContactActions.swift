import Foundation
import UIKit

enum ContactActions {

    static func call(phone: String) {
        let digits = PhoneFormatter.digitsOnly(phone)
        guard !digits.isEmpty, let url = URL(string: "tel:+\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    // Opens a Telegram chat by phone number via the t.me universal link.
    // With Telegram installed iOS routes this straight into the app on the
    // correct chat; without it, Safari shows the "open chat" page.
    static func openTelegram(phone: String) {
        let digits = PhoneFormatter.digitsOnly(phone)
        guard !digits.isEmpty, let url = URL(string: "https://t.me/+\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    static func openEmail(_ address: String) {
        let trimmed = address.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let url = URL(string: "mailto:\(trimmed)") else { return }
        UIApplication.shared.open(url)
    }

    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
