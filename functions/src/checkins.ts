// functions/src/checkins.ts — onCheckIn: GPS validation, daily limit, streak, points
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { distanceBetween } from "geofire-common";

const db = admin.firestore();

const CHECK_IN_RADIUS_KM = 0.1; // 100 meters
const MAX_CHECKINS_PER_DAY = 2;
const MIN_HOURS_BETWEEN = 3;
const CHECK_IN_POINTS = 10;
const STREAK_7_DAY_BONUS = 50;
const STREAK_30_DAY_BONUS = 200;

export const checkIn = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required");
  }

  const { spotId, lat, lng } = data as {
    spotId: string;
    lat: number;
    lng: number;
  };
  const userId = context.auth.uid;
  const now = admin.firestore.Timestamp.now();
  const nowDate = now.toDate();

  // ── GPS proximity check ──────────────────────────────────────
  const spotRef = db.collection("spots").doc(spotId);
  const spot = await spotRef.get();
  if (!spot.exists) {
    throw new functions.https.HttpsError("not-found", "Spot not found");
  }

  const gp = spot.data()?.geopoint as admin.firestore.GeoPoint;
  const distanceKm = distanceBetween([lat, lng], [gp.latitude, gp.longitude]);
  if (distanceKm > CHECK_IN_RADIUS_KM) {
    throw new functions.https.HttpsError(
      "out-of-range",
      `too far: You are ${Math.round(distanceKm * 1000)}m away. Must be within 100m.`
    );
  }

  return db.runTransaction(async (tx) => {
    const walletRef = db.collection("wallets").doc(userId);
    const wallet = await tx.get(walletRef);
    const wData = wallet.data() ?? {};

    // ── Daily limit check ────────────────────────────────────
    const todayStart = new Date(nowDate);
    todayStart.setHours(0, 0, 0, 0);

    const recentCheckins = await db
      .collection("checkins")
      .where("userId", "==", userId)
      .where("spotId", "==", spotId)
      .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(todayStart))
      .get();

    if (recentCheckins.size >= MAX_CHECKINS_PER_DAY) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Daily limit: Max 2 check-ins per spot per day"
      );
    }

    // ── Minimum gap check ────────────────────────────────────
    if (!recentCheckins.empty) {
      const lastCheckin = recentCheckins.docs[recentCheckins.docs.length - 1];
      const lastTime: Date = lastCheckin.data().timestamp.toDate();
      const diffHours =
        (nowDate.getTime() - lastTime.getTime()) / (1000 * 60 * 60);
      if (diffHours < MIN_HOURS_BETWEEN) {
        const remaining = Math.ceil(MIN_HOURS_BETWEEN - diffHours);
        throw new functions.https.HttpsError(
          "resource-exhausted",
          `Please wait ${remaining}h before checking in again`
        );
      }
    }

    // ── Compute streak ───────────────────────────────────────
    let streak = (wData.streak as number) ?? 0;
    const lastCheckinDate: Date | null = wData.lastCheckinDate?.toDate() ?? null;
    let streakBonus = 0;

    if (lastCheckinDate) {
      const yesterday = new Date(nowDate);
      yesterday.setDate(yesterday.getDate() - 1);
      const sameDay =
        lastCheckinDate.toDateString() === nowDate.toDateString();
      const consecutive =
        lastCheckinDate.toDateString() === yesterday.toDateString();

      if (sameDay) {
        // Already checked in today — don't increment streak
      } else if (consecutive) {
        streak += 1;
        if (streak === 7) streakBonus = STREAK_7_DAY_BONUS;
        if (streak === 30) streakBonus = STREAK_30_DAY_BONUS;
      } else {
        streak = 1; // Reset streak
      }
    } else {
      streak = 1;
    }

    const totalPoints = CHECK_IN_POINTS + streakBonus;

    // ── Write check-in record ────────────────────────────────
    const checkinRef = db.collection("checkins").doc();
    tx.set(checkinRef, {
      userId,
      spotId,
      timestamp: now,
      lat,
      lng,
      valid: true,
      pointsEarned: totalPoints,
    });

    // ── Update wallet ────────────────────────────────────────
    const newBalance = (wData.balance as number ?? 0) + totalPoints;
    const newLifetime = (wData.lifetimeEarned as number ?? 0) + totalPoints;
    const newBadges = [...(wData.badges as string[] ?? [])];
    if (streak === 7 && !newBadges.includes("🔥 7-Day Streak")) {
      newBadges.push("🔥 7-Day Streak");
    }
    if (streak === 30 && !newBadges.includes("⚡ Monthly Champion")) {
      newBadges.push("⚡ Monthly Champion");
    }

    tx.update(walletRef, {
      balance: newBalance,
      lifetimeEarned: newLifetime,
      streak,
      lastCheckinDate: now,
      totalCheckins: admin.firestore.FieldValue.increment(1),
      badges: newBadges,
    });

    // ── Update spot ──────────────────────────────────────────
    tx.update(spotRef, {
      checkinsCount: admin.firestore.FieldValue.increment(1),
      lastCheckin: now,
    });

    // ── Update leaderboard ───────────────────────────────────
    const lbRef = db.collection("leaderboard").doc(userId);
    tx.update(lbRef, {
      weekPoints: admin.firestore.FieldValue.increment(totalPoints),
      monthPoints: admin.firestore.FieldValue.increment(totalPoints),
      allTimePoints: admin.firestore.FieldValue.increment(totalPoints),
    });

    functions.logger.info(
      `Check-in: user=${userId} spot=${spotId} pts=${totalPoints} streak=${streak}`
    );

    return { pointsEarned: totalPoints, streak };
  });
});
