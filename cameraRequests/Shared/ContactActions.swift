import Foundation
import UIKit

enum ContactActions {

    @discardableResult
    static func call(phone: String) -> Bool {
        let digits = PhoneFormatter.digitsOnly(phone)
        guard !digits.isEmpty,
              let url = URL(string: "tel:+\(digits)") else { return false }
        return openIfPossible(url)
    }

    @discardableResult
    static func openTelegram(phone: String) -> Bool {
        let digits = PhoneFormatter.digitsOnly(phone)
        guard !digits.isEmpty,
              let url = URL(string: "https://t.me/+\(digits)") else { return false }
        return openIfPossible(url)
    }

    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }

    private static func openIfPossible(_ url: URL) -> Bool {
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url)
        return true
    }
}
