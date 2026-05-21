import type { VercelRequest, VercelResponse } from "@vercel/node";
import * as admin from "firebase-admin";
import { db, messaging } from "../../src/firebase";
import { selectPushTargets } from "../../src/userFilter";
import { sendLeadPush } from "../../src/pushService";
import { LeadDoc } from "../../src/types";

export const config = { maxDuration: 30 };

const REMINDER_INTERVAL_MINUTES = 20;
const SCAN_BATCH_LIMIT = 100;

function header(req: VercelRequest, name: string): string | undefined {
  const v = req.headers[name.toLowerCase()];
  return Array.isArray(v) ? v[0] : v;
}

function formatBody(lead: LeadDoc): string {
  const parts = [lead.name, lead.phone].filter((p) => p && p.length > 0);
  return parts.join(" · ") || "Без контактов";
}

// POST /api/cron/remind — invoked every ~5 min by cron-job.org.
// Sends a reminder for every "new" lead older than REMINDER_INTERVAL_MINUTES
// that hasn't been reminded within that same window.
export default async function handler(req: VercelRequest, res: VercelResponse): Promise<void> {
  if (req.method !== "POST") {
    res.status(405).json({ error: "method_not_allowed" });
    return;
  }

  const provided = header(req, "x-cron-secret");
  if (!provided || provided !== process.env.CRON_SECRET) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  try {
    const firestore = db();
    const now = new Date();
    const cutoff = admin.firestore.Timestamp.fromMillis(
      now.getTime() - REMINDER_INTERVAL_MINUTES * 60 * 1000,
    );

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
      const lead = doc.data() as LeadDoc;
      const lastReminded = lead.lastRemindedAt as
        | admin.firestore.Timestamp
        | null
        | undefined;
      if (!lastReminded) return true;
      return lastReminded.toMillis() < cutoff.toMillis();
    });

    if (due.length === 0) {
      res.status(200).json({ processed: 0, reason: "none_due" });
      return;
    }

    const targets = await selectPushTargets(firestore, "reminder", now);
    let pushed = 0;

    for (const doc of due) {
      const lead = doc.data() as LeadDoc;

      // Always update bookkeeping, even with zero targets — prevents the lead
      // from looping in the query when every user is in quiet hours.
      const writePromise = doc.ref.update({
        lastRemindedAt: admin.firestore.FieldValue.serverTimestamp(),
        reminderCount: admin.firestore.FieldValue.increment(1),
      });

      if (targets.length > 0) {
        try {
          await sendLeadPush(firestore, messaging(), targets, {
            leadId: doc.id,
            title: "Заявка ждёт ответа",
            body: formatBody(lead),
          });
          pushed += 1;
        } catch (err) {
          console.error("[remind] push failed", doc.id, err);
        }
      }
      await writePromise;
    }

    console.info("[remind] done", { due: due.length, targets: targets.length, pushed });
    res.status(200).json({ processed: due.length, targets: targets.length, pushed });
  } catch (err) {
    console.error("[remind] error", err);
    res.status(500).json({ error: "internal" });
  }
}
