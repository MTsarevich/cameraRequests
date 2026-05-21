import * as admin from "firebase-admin";
import { UserPushTarget } from "./userFilter";

export interface LeadNotification {
  leadId: string;
  title: string;
  body: string;
}

// Sends the same notification to every target, customising sound per user.
// Stale tokens (invalid-registration-token / not-registered) are pruned from users/{uid}/fcmTokens.
export async function sendLeadPush(
  db: admin.firestore.Firestore,
  messaging: admin.messaging.Messaging,
  targets: UserPushTarget[],
  notification: LeadNotification,
): Promise<{ successCount: number; failureCount: number }> {
  let successCount = 0;
  let failureCount = 0;

  await Promise.all(
    targets.map(async (target) => {
      const message: admin.messaging.MulticastMessage = {
        tokens: target.tokens,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          leadId: notification.leadId,
        },
        apns: {
          payload: {
            aps: {
              sound: target.soundEnabled ? "default" : undefined,
              badge: 1,
              "content-available": 1,
            },
          },
        },
      };

      try {
        const response = await messaging.sendEachForMulticast(message);
        successCount += response.successCount;
        failureCount += response.failureCount;

        const staleTokens: string[] = [];
        response.responses.forEach((r, idx) => {
          if (!r.success) {
            const code = r.error?.code ?? "";
            if (
              code === "messaging/invalid-registration-token" ||
              code === "messaging/registration-token-not-registered"
            ) {
              staleTokens.push(target.tokens[idx]);
            } else {
              console.warn("[push] FCM send error", target.uid, code, r.error?.message);
            }
          }
        });

        if (staleTokens.length > 0) {
          await db.collection("users").doc(target.uid).update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
          });
          console.info("[push] pruned stale tokens", target.uid, staleTokens.length);
        }
      } catch (err) {
        failureCount += target.tokens.length;
        console.error("[push] FCM send failed", target.uid, err);
      }
    }),
  );

  return { successCount, failureCount };
}
