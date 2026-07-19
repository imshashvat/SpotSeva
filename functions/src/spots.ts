// functions/src/spots.ts — adoptSpot + releaseSpot callable functions
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

const ADOPT_POINTS = 50;

export const adoptSpot = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");

  const { spotId } = data as { spotId: string };
  const userId = context.auth.uid;

  return db.runTransaction(async (tx) => {
    const spotRef = db.collection("spots").doc(spotId);
    const walletRef = db.collection("wallets").doc(userId);
    const userRef = db.collection("users").doc(userId);

    const [spot, wallet] = await Promise.all([tx.get(spotRef), tx.get(walletRef)]);

    if (!spot.exists) {
      throw new functions.https.HttpsError("not-found", "Spot not found");
    }
    if (spot.data()?.adopterId) {
      throw new functions.https.HttpsError("already-exists", "Spot already adopted");
    }
    const currentAdopted = wallet.data()?.adoptedSpotId;
    if (currentAdopted && currentAdopted !== "") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "You can only adopt one spot at a time. Release your current spot first."
      );
    }

    const now = admin.firestore.Timestamp.now();

    // Update spot
    tx.update(spotRef, {
      adopterId: userId,
      status: "adopted",
      adoptedAt: now,
    });

    // Award points
    const currentBalance = wallet.data()?.balance ?? 0;
    const currentLifetime = wallet.data()?.lifetimeEarned ?? 0;
    tx.update(walletRef, {
      balance: currentBalance + ADOPT_POINTS,
      lifetimeEarned: currentLifetime + ADOPT_POINTS,
      adoptedSpotId: spotId,
    });

    // Update user doc
    tx.update(userRef, { adoptedSpotId: spotId });

    // Update leaderboard
    const lbRef = db.collection("leaderboard").doc(userId);
    tx.update(lbRef, {
      weekPoints: admin.firestore.FieldValue.increment(ADOPT_POINTS),
      monthPoints: admin.firestore.FieldValue.increment(ADOPT_POINTS),
      allTimePoints: admin.firestore.FieldValue.increment(ADOPT_POINTS),
    });

    return { spotId, pointsEarned: ADOPT_POINTS };
  });
});

export const releaseSpot = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");

  const { spotId } = data as { spotId: string };
  const userId = context.auth.uid;

  return db.runTransaction(async (tx) => {
    const spotRef = db.collection("spots").doc(spotId);
    const walletRef = db.collection("wallets").doc(userId);
    const userRef = db.collection("users").doc(userId);

    const spot = await tx.get(spotRef);
    if (spot.data()?.adopterId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "Not your spot");
    }

    tx.update(spotRef, { adopterId: "", status: "clean" });
    tx.update(walletRef, { adoptedSpotId: "" });
    tx.update(userRef, { adoptedSpotId: "" });

    return { success: true };
  });
});
