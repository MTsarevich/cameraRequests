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
exports.handleIngestLead = handleIngestLead;
const admin = __importStar(require("firebase-admin"));
const firebase_1 = require("./firebase");
const phone_1 = require("./phone");
const userFilter_1 = require("./userFilter");
const pushService_1 = require("./pushService");
const MAX_FIELD_LEN = 500;
const DEDUP_WINDOW_SECONDS = 60;
function asString(value, maxLen = MAX_FIELD_LEN) {
    if (typeof value !== "string")
        return undefined;
    const trimmed = value.trim();
    if (!trimmed)
        return undefined;
    return trimmed.slice(0, maxLen);
}
function formatBody(name, phone) {
    const parts = [name, phone].filter((p) => p && p.length > 0);
    return parts.join(" · ") || "Без контактов";
}
// POST /ingestLead — receives a lead from the website, stores it, and pushes
// a "new lead" notification immediately (no Firestore trigger needed).
async function handleIngestLead(req, res) {
    const provided = req.get("X-Ingest-Secret");
    if (!provided || provided !== process.env.INGEST_SECRET) {
        res.status(401).json({ error: "unauthorized" });
        return;
    }
    const body = (req.body ?? {});
    const name = asString(body.name) ?? "";
    const rawPhone = asString(body.phone) ?? "";
    const phone = rawPhone ? (0, phone_1.normalizePhone)(rawPhone) : "";
    const message = asString(body.message);
    const pageUrl = asString(body.pageUrl);
    const source = asString(body.source) ?? "website";
    if (!name && !phone) {
        res.status(400).json({ error: "name_or_phone_required" });
        return;
    }
    const firestore = (0, firebase_1.db)();
    // Dedup by phone within DEDUP_WINDOW_SECONDS.
    if (phone) {
        const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - DEDUP_WINDOW_SECONDS * 1000);
        const existing = await firestore
            .collection("leads")
            .where("phone", "==", phone)
            .where("createdAt", ">", cutoff)
            .orderBy("createdAt", "desc")
            .limit(1)
            .get();
        if (!existing.empty) {
            const doc = existing.docs[0];
            await doc.ref.update({
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.info("[ingestLead] dedup hit", doc.id, phone);
            res.status(200).json({ leadId: doc.id, deduped: true });
            return;
        }
    }
    const docRef = firestore.collection("leads").doc();
    await docRef.set({
        name,
        phone,
        message: message ?? null,
        pageUrl: pageUrl ?? null,
        source,
        status: "new",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastRemindedAt: null,
        reminderCount: 0,
        rawPayload: body,
    });
    console.info("[ingestLead] lead created", docRef.id, name, phone, source);
    // Respond before push so the website's fire-and-forget request returns fast.
    res.status(200).json({ leadId: docRef.id, deduped: false });
    // Push happens after the response. Wrapped so a push failure never 500s the caller.
    try {
        const targets = await (0, userFilter_1.selectPushTargets)(firestore, "newLead", new Date());
        if (targets.length === 0) {
            console.info("[ingestLead] no eligible push targets (quiet/disabled)", docRef.id);
            return;
        }
        const { successCount, failureCount } = await (0, pushService_1.sendLeadPush)(firestore, (0, firebase_1.messaging)(), targets, {
            leadId: docRef.id,
            title: "Новая заявка",
            body: formatBody(name, phone),
        });
        console.info("[ingestLead] push sent", docRef.id, { successCount, failureCount });
    }
    catch (err) {
        console.error("[ingestLead] push failed", docRef.id, err);
    }
}
//# sourceMappingURL=ingestLead.js.map