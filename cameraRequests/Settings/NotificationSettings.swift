import Foundation

struct NotificationSettings: Codable, Equatable {
    var newLeadEnabled: Bool = true
    var remindersEnabled: Bool = true
    var quietHoursEnabled: Bool = true
    var quietStartHour: Int = 1
    var quietEndHour: Int = 8
    var timezone: String = "Europe/Moscow"
    var soundEnabled: Bool = true

    static let `default` = NotificationSettings()

    // List of timezones we expose in the picker. Covers RU + a few neighbours.
    static let supportedTimezones: [String] = [
        "Europe/Kaliningrad",
        "Europe/Moscow",
        "Europe/Samara",
        "Asia/Yekaterinburg",
        "Asia/Omsk",
        "Asia/Krasnoyarsk",
        "Asia/Irkutsk",
        "Asia/Yakutsk",
        "Asia/Vladivostok",
        "Asia/Magadan",
        "Asia/Kamchatka",
        "Europe/London",
        "Europe/Berlin",
        "America/New_York",
        "America/Los_Angeles",
        "Asia/Dubai",
        "Asia/Tbilisi",
        "Asia/Tashkent",
        "Asia/Almaty",
    ]
}
