import Foundation
import UIKit

enum ContactActions {

    static func call(phone: String) {
        let digits = PhoneFormatter.digitsOnly(phone)
        guard !digits.isEmpty, let url = URL(string: "tel:+\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    // Opens a Telegram chat by phone number. Tries the tg:// app scheme first
    // (opens the installed Telegram app directly); falls back to the t.me web
    // link if Telegram isn't installed.
    static func openTelegram(phone: String) {
        let digits = PhoneFormatter.digitsOnly(phone)
        guard !digits.isEmpty else { return }
        let appURL = URL(string: "tg://resolve?phone=\(digits)")
        let webURL = URL(string: "https://t.me/+\(digits)")

        if let appURL {
            UIApplication.shared.open(appURL) { opened in
                if !opened, let webURL {
                    UIApplication.shared.open(webURL)
                }
            }
        } else if let webURL {
            UIApplication.shared.open(webURL)
        }
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
