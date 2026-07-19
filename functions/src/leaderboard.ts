// functions/src/leaderboard.ts — hourly leaderboard recomputation
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

export const computeLeaderboard = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    // Week reset boundary: Monday 00:00
    const todayMs = now.toMillis();
    const startOfWeek = new Date(todayMs);
    startOfWeek.setDate(
      startOfWeek.getDate() - startOfWeek.getDay() + (startOfWeek.getDay() === 0 ? -6 : 1)
    );
    startOfWeek.setHours(0, 0, 0, 0);

    // Month reset boundary: 1st of month
    const startOfMonth = new Date(todayMs);
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    // Sum check-in + report points for week period
    const [weekCheckins, weekReports, monthCheckins, monthReports] =
      await Promise.all([
        db
          .collection("checkins")
          .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(startOfWeek))
          .where("valid", "==", true)
          .get(),
        db
          .collection("reports")
          .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(startOfWeek))
          .where("isValid", "==", true)
          .get(),
        db
          .collection("checkins")
          .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(startOfMonth))
          .where("valid", "==", true)
          .get(),
        db
          .collection("reports")
          .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(startOfMonth))
          .where("isValid", "==", true)
          .get(),
      ]);

    const weekMap = new Map<string, number>();
    const monthMap = new Map<string, number>();

    weekCheckins.forEach((d) => {
      const uid: string = d.data().userId;
      weekMap.set(uid, (weekMap.get(uid) ?? 0) + (d.data().pointsEarned ?? 10));
    });
    weekReports.forEach((d) => {
      const uid: string = d.data().reporterId;
      weekMap.set(uid, (weekMap.get(uid) ?? 0) + (d.data().pointsEarned ?? 25));
    });
    monthCheckins.forEach((d) => {
      const uid: string = d.data().userId;
      monthMap.set(uid, (monthMap.get(uid) ?? 0) + (d.data().pointsEarned ?? 10));
    });
    monthReports.forEach((d) => {
      const uid: string = d.data().reporterId;
      monthMap.set(uid, (monthMap.get(uid) ?? 0) + (d.data().pointsEarned ?? 25));
    });

    // Write to leaderboard collection in batches of 500
    const allUids = new Set([...weekMap.keys(), ...monthMap.keys()]);
    const batches: admin.firestore.WriteBatch[] = [];
    let batch = db.batch();
    let count = 0;

    for (const uid of allUids) {
      const lbRef = db.collection("leaderboard").doc(uid);
      batch.update(lbRef, {
        weekPoints: weekMap.get(uid) ?? 0,
        monthPoints: monthMap.get(uid) ?? 0,
        lastUpdated: now,
      });
      count++;
      if (count % 499 === 0) {
        batches.push(batch);
        batch = db.batch();
      }
    }
    batches.push(batch);

    await Promise.all(batches.map((b) => b.commit()));

    functions.logger.info(
      `Leaderboard updated for ${allUids.size} users`
    );
    return null;
  });
