// functions/src/antifraud.ts — detectSuspiciousActivity + auto-release stale spots
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

export const detectSuspiciousActivity = functions.pubsub
  .schedule("every 6 hours")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const sixHoursAgo = new Date(now.toMillis() - 6 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(now.toMillis() - 7 * 24 * 60 * 60 * 1000);

    // ── 1. Flag users with >10 check-ins in 6 hours ──────────
    const recentCheckins = await db
      .collection("checkins")
      .where("timestamp", ">", admin.firestore.Timestamp.fromDate(sixHoursAgo))
      .where("valid", "==", true)
      .get();

    const byUser = new Map<string, number>();
    recentCheckins.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      const uid: string = doc.data().userId as string;
      byUser.set(uid, (byUser.get(uid) ?? 0) + 1);
    });

    const flaggedUsers: string[] = [];
    const flagBatch = db.batch();

    byUser.forEach((count, uid) => {
      if (count > 10) {
        flaggedUsers.push(uid);
        const userRef = db.collection("users").doc(uid);
        const walletRef = db.collection("wallets").doc(uid);
        flagBatch.update(userRef, {
          flagged: true,
          flagReason: `Suspicious: ${count} check-ins in 6h`,
          flaggedAt: now,
        });
        flagBatch.update(walletRef, {
          flagged: true,
          flagReason: `Suspicious: ${count} check-ins in 6h`,
        });
      }
    });

    if (flaggedUsers.length > 0) {
      await flagBatch.commit();
    }

    // ── 2. Auto-release stale spots (no check-in for 7 days) ─
    const staleSpots = await db
      .collection("spots")
      .where("adopterId", "!=", "")
      .where("lastCheckin", "<", admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .get();

    const releaseBatch = db.batch();
    const releasedAdopters: string[] = [];

    staleSpots.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      const adopterId: string = doc.data().adopterId;
      releaseBatch.update(doc.ref, {
        adopterId: "",
        status: "clean",
        autoReleasedAt: now,
      });
      if (adopterId) {
        releasedAdopters.push(adopterId);
        const walletRef = db.collection("wallets").doc(adopterId);
        const userRef = db.collection("users").doc(adopterId);
        releaseBatch.update(walletRef, { adoptedSpotId: "" });
        releaseBatch.update(userRef, { adoptedSpotId: "" });
      }
    });

    await releaseBatch.commit();

    functions.logger.info(
      `Anti-fraud scan: flagged ${flaggedUsers.length} users, released ${staleSpots.size} stale spots`
    );

    return null;
  });
