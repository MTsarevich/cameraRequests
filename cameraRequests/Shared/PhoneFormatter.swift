import Foundation

enum PhoneFormatter {

    // Pretty-print a +375XXXXXXXXX number as "+375 (29) 123-45-67".
    // Numbers that aren't Belarusian E.164 are returned unchanged.
    static func display(_ phone: String) -> String {
        guard !phone.isEmpty else { return "" }
        let digits = phone.filter(\.isWholeNumber)
        if digits.hasPrefix("375"), digits.count == 12 {
            return formatBelarus(digits)
        }
        return phone
    }

    private static func formatBelarus(_ digits: String) -> String {
        let chars = Array(digits)
        guard chars.count == 12 else { return digits }
        let code = String(chars[3...4])    // operator code, e.g. 29
        let p1 = String(chars[5...7])      // 123
        let p2 = String(chars[8...9])      // 45
        let p3 = String(chars[10...11])    // 67
        return "+375 (\(code)) \(p1)-\(p2)-\(p3)"
    }

    // Returns the digits-only form, no leading "+", suitable for tel:, t.me URLs.
    static func digitsOnly(_ phone: String) -> String {
        phone.filter(\.isWholeNumber)
    }
}
