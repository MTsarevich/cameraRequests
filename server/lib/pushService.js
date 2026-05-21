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
exports.sendLeadPush = sendLeadPush;
const admin = __importStar(require("firebase-admin"));
// Sends the same notification to every target, customising sound per user.
// Stale tokens (invalid-registration-token / not-registered) are pruned from users/{uid}/fcmTokens.
async function sendLeadPush(db, messaging, targets, notification) {
    let successCount = 0;
    let failureCount = 0;
    await Promise.all(targets.map(async (target) => {
        const message = {
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
            const staleTokens = [];
            response.responses.forEach((r, idx) => {
                if (!r.success) {
                    const code = r.error?.code ?? "";
                    if (code === "messaging/invalid-registration-token" ||
                        code === "messaging/registration-token-not-registered") {
                        staleTokens.push(target.tokens[idx]);
                    }
                    else {
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
        }
        catch (err) {
            failureCount += target.tokens.length;
            console.error("[push] FCM send failed", target.uid, err);
        }
    }));
    return { successCount, failureCount };
}
//# sourceMappingURL=pushService.js.map