"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.mergeSettings = mergeSettings;
exports.isQuietForUser = isQuietForUser;
exports.isQuietHourRange = isQuietHourRange;
const luxon_1 = require("luxon");
const types_1 = require("./types");
function mergeSettings(partial) {
    return { ...types_1.DEFAULT_NOTIFICATION_SETTINGS, ...(partial ?? {}) };
}
// Returns true if `now` falls inside the user's quiet window.
// Window can cross midnight (e.g. 23:00–07:00). When start == end, quiet is disabled.
function isQuietForUser(settings, now) {
    const s = mergeSettings(settings);
    if (!s.quietHoursEnabled)
        return false;
    if (s.quietStartHour === s.quietEndHour)
        return false;
    const local = luxon_1.DateTime.fromJSDate(now).setZone(s.timezone);
    if (!local.isValid) {
        // Bad timezone → fall back to UTC; don't crash.
        return isQuietHourRange(now.getUTCHours(), s.quietStartHour, s.quietEndHour);
    }
    return isQuietHourRange(local.hour, s.quietStartHour, s.quietEndHour);
}
function isQuietHourRange(hour, startHour, endHour) {
    if (startHour === endHour)
        return false;
    if (startHour < endHour) {
        // Same-day window, e.g. 13–15.
        return hour >= startHour && hour < endHour;
    }
    // Crosses midnight, e.g. 23–7.
    return hour >= startHour || hour < endHour;
}
//# sourceMappingURL=quietHours.js.map