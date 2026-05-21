import type { VercelRequest, VercelResponse } from "@vercel/node";
import * as admin from "firebase-admin";
import { db, messaging } from "../src/firebase";
import { normalizePhone } from "../src/phone";
import { selectPushTargets } from "../src/userFilter";
import { sendLeadPush } from "../src/pushService";
import { countNewLeads } from "../src/leadCounts";

const MAX_FIELD_LEN = 500;
const DEDUP_WINDOW_SECONDS = 15;

function asString(value: unknown, maxLen = MAX_FIELD_LEN): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  if (!trimmed) return undefined;
  return trimmed.slice(0, maxLen);
}

function header(req: VercelRequest, name: string): string | undefined {
  const v = req.headers[name.toLowerCase()];
  return Array.isArray(v) ? v[0] : v;
}

function formatBody(name: string, phone: string): string {
  const parts = [name, phone].filter((p) => p && p.length > 0);
  return parts.join(" · ") || "Без контактов";
}

// POST /api/ingestLead — receives a lead from the website, stores it, and
// pushes a "new lead" notification before responding. On Vercel the function
// may be frozen right after the response, so the push is awaited first.
export default async function handler(req: VercelRequest, res: VercelResponse): Promise<void> {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, X-Ingest-Secret");

  if (req.method === "OPTIONS") {
    res.status(204).end();
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({ error: "method_not_allowed" });
    return;
  }

  const provided = header(req, "x-ingest-secret");
  if (!provided || provided !== process.env.INGEST_SECRET) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  const body = (req.body ?? {}) as Record<string, unknown>;
  const name = asString(body.name) ?? "";
  const rawPhone = asString(body.phone) ?? "";
  const phone = rawPhone ? normalizePhone(rawPhone) : "";
  const email = asString(body.email);
  const message = asString(body.message);
  const pageUrl = asString(body.pageUrl);
  const source = asString(body.source) ?? "website";

  if (!name && !phone) {
    res.status(400).json({ error: "name_or_phone_required" });
    return;
  }

  try {
    const firestore = db();

    // Dedup by phone within DEDUP_WINDOW_SECONDS.
    if (phone) {
      const cutoff = admin.firestore.Timestamp.fromMillis(
        Date.now() - DEDUP_WINDOW_SECONDS * 1000,
      );
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
      email: email ?? null,
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

    // Push must finish before we respond — Vercel may freeze the function
    // immediately after res. A push failure must not fail the request.
    try {
      const targets = await selectPushTargets(firestore, "newLead", new Date());
      if (targets.length > 0) {
        const badge = await countNewLeads(firestore);
        const result = await sendLeadPush(firestore, messaging(), targets, {
          leadId: docRef.id,
          title: "Новая заявка",
          body: formatBody(name, phone),
          badge,
        });
        console.info("[ingestLead] push sent", docRef.id, result);
      } else {
        console.info("[ingestLead] no eligible push targets", docRef.id);
      }
    } catch (pushErr) {
      console.error("[ingestLead] push failed", docRef.id, pushErr);
    }

    res.status(200).json({ leadId: docRef.id, deduped: false });
  } catch (err) {
    console.error("[ingestLead] error", err);
    res.status(500).json({ error: "internal" });
  }
}
