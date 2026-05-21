import { DateTime } from "luxon";
import { NotificationSettings, DEFAULT_NOTIFICATION_SETTINGS } from "./types";

export function mergeSettings(partial?: Partial<NotificationSettings>): NotificationSettings {
  return { ...DEFAULT_NOTIFICATION_SETTINGS, ...(partial ?? {}) };
}

// Returns true if `now` falls inside the user's quiet window.
// Window can cross midnight (e.g. 23:00–07:00). When start == end, quiet is disabled.
export function isQuietForUser(
  settings: Partial<NotificationSettings> | undefined,
  now: Date,
): boolean {
  const s = mergeSettings(settings);
  if (!s.quietHoursEnabled) return false;
  if (s.quietStartHour === s.quietEndHour) return false;

  const local = DateTime.fromJSDate(now).setZone(s.timezone);
  if (!local.isValid) {
    // Bad timezone → fall back to UTC; don't crash.
    return isQuietHourRange(now.getUTCHours(), s.quietStartHour, s.quietEndHour);
  }
  return isQuietHourRange(local.hour, s.quietStartHour, s.quietEndHour);
}

export function isQuietHourRange(hour: number, startHour: number, endHour: number): boolean {
  if (startHour === endHour) return false;
  if (startHour < endHour) {
    // Same-day window, e.g. 13–15.
    return hour >= startHour && hour < endHour;
  }
  // Crosses midnight, e.g. 23–7.
  return hour >= startHour || hour < endHour;
}
