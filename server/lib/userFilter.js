"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.selectPushTargets = selectPushTargets;
const quietHours_1 = require("./quietHours");
// Loads all users and filters them by their notification settings for a given push kind.
// Returns one entry per eligible user. Users without tokens are skipped.
async function selectPushTargets(db, kind, now = new Date()) {
    const snapshot = await db.collection("users").get();
    const targets = [];
    for (const doc of snapshot.docs) {
        const user = doc.data();
        const settings = (0, quietHours_1.mergeSettings)(user.notificationSettings);
        if (kind === "newLead" && !settings.newLeadEnabled)
            continue;
        if (kind === "reminder" && !settings.remindersEnabled)
            continue;
        if ((0, quietHours_1.isQuietForUser)(settings, now))
            continue;
        const tokens = (user.fcmTokens ?? []).filter((t) => typeof t === "string" && t.length > 0);
        if (tokens.length === 0)
            continue;
        targets.push({
            uid: doc.id,
            tokens,
            soundEnabled: settings.soundEnabled,
        });
    }
    return targets;
}
//# sourceMappingURL=userFilter.js.map