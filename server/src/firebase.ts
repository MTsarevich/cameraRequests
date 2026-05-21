import * as admin from "firebase-admin";

// Reads the service account from FIREBASE_SERVICE_ACCOUNT.
// Accepts either raw JSON or (preferred) a base64-encoded JSON blob.
function loadServiceAccount(): admin.ServiceAccount {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw || !raw.trim()) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT env var is not set");
  }
  const text = raw.trim().startsWith("{")
    ? raw
    : Buffer.from(raw, "base64").toString("utf8");
  try {
    return JSON.parse(text) as admin.ServiceAccount;
  } catch {
    throw new Error("FIREBASE_SERVICE_ACCOUNT is not valid JSON (or base64 of JSON)");
  }
}

let app: admin.app.App | undefined;

function getApp(): admin.app.App {
  if (!app) {
    app = admin.initializeApp({
      credential: admin.credential.cert(loadServiceAccount()),
    });
  }
  return app;
}

export function db(): admin.firestore.Firestore {
  return getApp().firestore();
}

export function messaging(): admin.messaging.Messaging {
  return getApp().messaging();
}
