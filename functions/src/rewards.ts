// functions/src/rewards.ts — redeemCoupon: atomic Firestore transaction
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { v4 as uuidv4 } from "uuid";

const db = admin.firestore();

function generateCouponCode(businessId: string): string {
  const prefix = businessId.substring(0, 3).toUpperCase();
  const unique = uuidv4().replace(/-/g, "").substring(0, 8).toUpperCase();
  return `${prefix}-${unique}`;
}

export const redeemCoupon = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required");
  }

  const { rewardId } = data as { rewardId: string };
  const userId = context.auth.uid;
  const now = admin.firestore.Timestamp.now();

  return db.runTransaction(async (tx) => {
    const rewardRef = db.collection("rewards").doc(rewardId);
    const walletRef = db.collection("wallets").doc(userId);

    const [reward, wallet] = await Promise.all([
      tx.get(rewardRef),
      tx.get(walletRef),
    ]);

    if (!reward.exists) {
      throw new functions.https.HttpsError("not-found", "Reward not found");
    }

    const rData = reward.data()!;
    const wData = wallet.data() ?? {};

    // ── Check stock ──────────────────────────────────────────
    const remaining = rData.totalQty - rData.redeemedQty;
    if (remaining <= 0) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Coupon sold out"
      );
    }

    // ── Check expiry ──────────────────────────────────────────
    const expiresAt: Date = rData.expiresAt.toDate();
    if (expiresAt < new Date()) {
      throw new functions.https.HttpsError("unavailable", "Coupon has expired");
    }

    // ── Check balance ────────────────────────────────────────
    const balance = wData.balance as number ?? 0;
    if (balance < rData.pointsCost) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Insufficient points. Need ${rData.pointsCost - balance} more points.`
      );
    }

    // ── Generate coupon code (post-transaction only) ─────────
    const couponCode = generateCouponCode(rData.businessId);

    // ── Atomic writes ────────────────────────────────────────
    const redemptionRef = db.collection("redemptions").doc();
    tx.set(redemptionRef, {
      userId,
      rewardId,
      couponCode,
      redeemedAt: now,
      used: false,
      pointsCost: rData.pointsCost,
      businessId: rData.businessId,
      businessName: rData.businessName,
      title: rData.title,
    });

    // Deduct points
    const newBalance = balance - rData.pointsCost;
    tx.update(walletRef, { balance: newBalance });

    // Increment redeemed count
    tx.update(rewardRef, {
      redeemedQty: admin.firestore.FieldValue.increment(1),
    });

    functions.logger.info(
      `Coupon redeemed: user=${userId} reward=${rewardId} code=${couponCode}`
    );

    return {
      couponCode,
      newBalance,
      expiresAt: now
        .toDate()
        .setDate(now.toDate().getDate() + 30)
        .toString(),
    };
  });
});
