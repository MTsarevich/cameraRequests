import * as admin from "firebase-admin";
import { isQuietForUser, mergeSettings } from "./quietHours";
import { UserDoc } from "./types";

export interface UserPushTarget {
  uid: string;
  tokens: string[];
  soundEnabled: boolean;
}

export type PushKind = "newLead" | "reminder";

// Loads all users and filters them by their notification settings for a given push kind.
// Returns one entry per eligible user. Users without tokens are skipped.
export async function selectPushTargets(
  db: admin.firestore.Firestore,
  kind: PushKind,
  now: Date = new Date(),
): Promise<UserPushTarget[]> {
  const snapshot = await db.collection("users").get();
  const targets: UserPushTarget[] = [];

  for (const doc of snapshot.docs) {
    const user = doc.data() as UserDoc;
    const settings = mergeSettings(user.notificationSettings);

    if (kind === "newLead" && !settings.newLeadEnabled) continue;
    if (kind === "reminder" && !settings.remindersEnabled) continue;
    if (isQuietForUser(settings, now)) continue;

    const tokens = (user.fcmTokens ?? []).filter((t) => typeof t === "string" && t.length > 0);
    if (tokens.length === 0) continue;

    targets.push({
      uid: doc.id,
      tokens,
      soundEnabled: settings.soundEnabled,
    });
  }

  return targets;
}
