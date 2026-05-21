"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleRemind = handleRemind;
const admin = __importStar(require("firebase-admin"));
const firebase_1 = require("./firebase");
const userFilter_1 = require("./userFilter");
const pushService_1 = require("./pushService");
const REMINDER_INTERVAL_MINUTES = 20;
const SCAN_BATCH_LIMIT = 100;
function formatBody(lead) {
    const parts = [lead.name, lead.phone].filter((p) => p && p.length > 0);
    return parts.join(" · ") || "Без контактов";
}
// POST /cron/remind — invoked every ~5 min by an external scheduler (cron-job.org).
// Sends a reminder for every "new" lead older than REMINDER_INTERVAL_MINUTES
// that hasn't been reminded within that same window.
async function handleRemind(req, res) {
    const provided = req.get("X-Cron-Secret");
    if (!provided || provided !== process.env.CRON_SECRET) {
        res.status(401).json({ error: "unauthorized" });
        return;
    }
    const firestore = (0, firebase_1.db)();
    const now = new Date();
    const cutoff = admin.firestore.Timestamp.fromMillis(now.getTime() - REMINDER_INTERVAL_MINUTES * 60 * 1000);
    const candidates = await firestore
        .collection("leads")
        .where("status", "==", "new")
        .where("createdAt", "<", cutoff)
        .orderBy("createdAt", "asc")
        .limit(SCAN_BATCH_LIMIT)
        .get();
    if (candidates.empty) {
        res.status(200).json({ processed: 0, reason: "no_candidates" });
        return;
    }
    // Filter in memory: lastRemindedAt == null OR lastRemindedAt < cutoff.
    const due = candidates.docs.filter((doc) => {
        const lead = doc.data();
        const lastReminded = lead.lastRemindedAt;
        if (!lastReminded)
            return true;
        return lastReminded.toMillis() < cutoff.toMillis();
    });
    if (due.length === 0) {
        res.status(200).json({ processed: 0, reason: "none_due" });
        return;
    }
    const targets = await (0, userFilter_1.selectPushTargets)(firestore, "reminder", now);
    let pushed = 0;
    for (const doc of due) {
        const lead = doc.data();
        // Always update bookkeeping, even with zero targets — prevents the lead
        // from looping in the query when every user is in quiet hours.
        const writePromise = doc.ref.update({
            lastRemindedAt: admin.firestore.FieldValue.serverTimestamp(),
            reminderCount: admin.firestore.FieldValue.increment(1),
        });
        if (targets.length > 0) {
            try {
                await (0, pushService_1.sendLeadPush)(firestore, (0, firebase_1.messaging)(), targets, {
                    leadId: doc.id,
                    title: "Заявка ждёт ответа",
                    body: formatBody(lead),
                });
                pushed += 1;
            }
            catch (err) {
                console.error("[remind] push failed", doc.id, err);
            }
        }
        await writePromise;
    }
    console.info("[remind] done", { due: due.length, targets: targets.length, pushed });
    res.status(200).json({ processed: due.length, targets: targets.length, pushed });
}
//# sourceMappingURL=remind.js.map