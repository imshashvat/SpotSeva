// functions/src/auth.ts — onUserCreate: initialise wallet + profile
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const ONBOARDING_BADGE = "🌱 Explorer";

export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const now = admin.firestore.Timestamp.now();

  const batch = db.batch();

  // ── User profile ─────────────────────────────────────────────
  const userRef = db.collection("users").doc(user.uid);
  batch.set(userRef, {
    uid: user.uid,
    displayName: user.displayName || "SpotSeva User",
    email: user.email || "",
    photoUrl: user.photoURL || "",
    phoneNumber: user.phoneNumber || "",
    role: "citizen",
    adoptedSpotId: "",
    createdAt: now,
    flagged: false,
    flagReason: "",
  });

  // ── Wallet ───────────────────────────────────────────────────
  const walletRef = db.collection("wallets").doc(user.uid);
  batch.set(walletRef, {
    balance: 0,
    lifetimeEarned: 0,
    streak: 0,
    lastCheckinDate: null,
    badges: [ONBOARDING_BADGE],
    totalReports: 0,
    totalCheckins: 0,
    displayName: user.displayName || "SpotSeva User",
    photoUrl: user.photoURL || "",
    adoptedSpotId: "",
    role: "citizen",
    flagged: false,
  });

  // ── Leaderboard entry ────────────────────────────────────────
  const lbRef = db.collection("leaderboard").doc(user.uid);
  batch.set(lbRef, {
    displayName: user.displayName || "SpotSeva User",
    photoUrl: user.photoURL || "",
    weekPoints: 0,
    monthPoints: 0,
    allTimePoints: 0,
    lastUpdated: now,
  });

  await batch.commit();

  // Send welcome notification if FCM token exists
  if (user.uid) {
    const tokenDoc = await db
      .collection("fcmTokens")
      .doc(user.uid)
      .get();
    if (tokenDoc.exists) {
      const token = tokenDoc.data()?.token;
      if (token) {
        await messaging.send({
          token,
          notification: {
            title: "Welcome to SpotSeva! 🌱",
            body: "Start adopting spots in your ward and earn rewards!",
          },
        });
      }
    }
  }

  functions.logger.info(`New user created: ${user.uid}`);
});
