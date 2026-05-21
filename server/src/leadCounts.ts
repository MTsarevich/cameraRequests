import * as admin from "firebase-admin";

// Count of leads still in the "new" state — used as the app icon badge number.
export async function countNewLeads(db: admin.firestore.Firestore): Promise<number> {
  const snap = await db.collection("leads").where("status", "==", "new").count().get();
  return snap.data().count;
}
