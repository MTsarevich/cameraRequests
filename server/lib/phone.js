"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.normalizePhone = normalizePhone;
// Normalize Belarusian phone input to E.164 (+375XXXXXXXXX).
// A Belarusian number is +375 + 2-digit operator code (25/29/33/44/…) + 7 digits.
// Examples:
//   "+375 29 123-45-67"  -> "+375291234567"
//   "80291234567"        -> "+375291234567"   (domestic long-distance form)
//   "0291234567"         -> "+375291234567"
//   "291234567"          -> "+375291234567"   (bare operator code + number)
function normalizePhone(input) {
    const trimmed = input.trim();
    if (!trimmed)
        return "";
    const digits = trimmed.replace(/\D+/g, "");
    if (!digits)
        return "";
    // Already international: 375 + 9 digits.
    if (digits.startsWith("375")) {
        return `+${digits}`;
    }
    // Domestic long-distance form: 8 0XX XXXXXXX (11 digits).
    if (digits.startsWith("80") && digits.length === 11) {
        return `+375${digits.slice(2)}`;
    }
    // Leading-zero form: 0XX XXXXXXX (10 digits).
    if (digits.startsWith("0") && digits.length === 10) {
        return `+375${digits.slice(1)}`;
    }
    // Bare operator code + number (9 digits).
    if (digits.length === 9) {
        return `+375${digits}`;
    }
    // Unknown shape — keep digits as an international number rather than dropping it.
    return `+${digits}`;
}
//# sourceMappingURL=phone.js.map