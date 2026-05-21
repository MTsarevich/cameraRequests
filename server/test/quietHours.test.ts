import { isQuietHourRange, isQuietForUser } from "../src/quietHours";
import { DEFAULT_NOTIFICATION_SETTINGS } from "../src/types";

describe("isQuietHourRange", () => {
  test("same-day window: 13–15 includes 14, excludes 12 and 15", () => {
    expect(isQuietHourRange(14, 13, 15)).toBe(true);
    expect(isQuietHourRange(13, 13, 15)).toBe(true);
    expect(isQuietHourRange(12, 13, 15)).toBe(false);
    expect(isQuietHourRange(15, 13, 15)).toBe(false);
  });

  test("crosses midnight: 23–7 includes 0, 5, 23 — excludes 8, 22", () => {
    expect(isQuietHourRange(0, 23, 7)).toBe(true);
    expect(isQuietHourRange(5, 23, 7)).toBe(true);
    expect(isQuietHourRange(23, 23, 7)).toBe(true);
    expect(isQuietHourRange(7, 23, 7)).toBe(false);
    expect(isQuietHourRange(8, 23, 7)).toBe(false);
    expect(isQuietHourRange(22, 23, 7)).toBe(false);
  });

  test("default 1–8 window matches plan", () => {
    expect(isQuietHourRange(2, 1, 8)).toBe(true);
    expect(isQuietHourRange(7, 1, 8)).toBe(true);
    expect(isQuietHourRange(8, 1, 8)).toBe(false);
    expect(isQuietHourRange(0, 1, 8)).toBe(false);
    expect(isQuietHourRange(23, 1, 8)).toBe(false);
  });

  test("start == end means disabled", () => {
    expect(isQuietHourRange(5, 0, 0)).toBe(false);
    expect(isQuietHourRange(0, 0, 0)).toBe(false);
  });
});

describe("isQuietForUser", () => {
  test("respects timezone — Moscow 03:00 = UTC 00:00", () => {
    const utcMidnight = new Date("2026-05-21T00:00:00.000Z");
    // Moscow is UTC+3, so this is 03:00 in Moscow — inside default 1–8 window.
    expect(isQuietForUser(DEFAULT_NOTIFICATION_SETTINGS, utcMidnight)).toBe(true);
  });

  test("respects timezone — Moscow 12:00 not quiet", () => {
    const utcNoon = new Date("2026-05-21T09:00:00.000Z"); // 12:00 Moscow
    expect(isQuietForUser(DEFAULT_NOTIFICATION_SETTINGS, utcNoon)).toBe(false);
  });

  test("returns false when quietHoursEnabled is false even at 03:00", () => {
    const utcMidnight = new Date("2026-05-21T00:00:00.000Z");
    expect(
      isQuietForUser({ ...DEFAULT_NOTIFICATION_SETTINGS, quietHoursEnabled: false }, utcMidnight),
    ).toBe(false);
  });

  test("undefined settings → uses defaults", () => {
    const utcMidnight = new Date("2026-05-21T00:00:00.000Z");
    expect(isQuietForUser(undefined, utcMidnight)).toBe(true);
  });

  test("bad timezone falls back gracefully (no throw)", () => {
    expect(() =>
      isQuietForUser(
        { ...DEFAULT_NOTIFICATION_SETTINGS, timezone: "Mars/Phobos" },
        new Date("2026-05-21T05:00:00.000Z"),
      ),
    ).not.toThrow();
  });
});
