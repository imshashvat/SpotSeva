// functions/src/reports.ts — submitReport (Groq AI) + onReportStatusChange
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import axios from "axios";


const db = admin.firestore();
const messaging = admin.messaging();

const REPORT_POINTS = 25;
const RESOLVED_BONUS = 50;
// pHash threshold defined in photoHash.ts (10 Hamming distance)

// ── Groq Vision API for issue classification ─────────────────────
async function classifyImage(imageUrl: string): Promise<{
  label: string;
  severity: "low" | "medium" | "high";
}> {
  const groqKey = functions.config().groq?.api_key ||
    process.env.GROQ_API_KEY || "";

  if (!groqKey) {
    return { label: "Civic issue detected", severity: "medium" };
  }

  try {
    const response = await axios.post(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        model: "llama-3.2-11b-vision-preview",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: { url: imageUrl },
              },
              {
                type: "text",
                text: `Analyze this civic/public space image and respond with JSON only:
{"label": "short description (max 8 words)", "severity": "low|medium|high"}
severity = high if: broken infrastructure, safety hazard, flooding, fallen tree
severity = medium if: litter, graffiti, damaged furniture, overgrown plants  
severity = low if: minor wear, aesthetic issues`,
              },
            ],
          },
        ],
        max_tokens: 100,
        temperature: 0.1,
      },
      {
        headers: {
          "Authorization": `Bearer ${groqKey}`,
          "Content-Type": "application/json",
        },
        timeout: 10000,
      }
    );

    const content = response.data.choices[0]?.message?.content || "{}";
    const parsed = JSON.parse(content.match(/\{.*\}/s)?.[0] || "{}");
    return {
      label: parsed.label || "Civic issue detected",
      severity: parsed.severity || "medium",
    };
  } catch (e) {
    functions.logger.warn("Groq classification failed:", e);
    return { label: "Civic issue detected", severity: "medium" };
  }
}

export const submitReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required");
  }

  const { spotId, photoUrls, issueType, description, lat, lng } = data as {
    spotId: string;
    photoUrls: string[];
    issueType: string;
    description: string;
    lat: number;
    lng: number;
  };
  const userId = context.auth.uid;
  const now = admin.firestore.Timestamp.now();

  if (!photoUrls?.length) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "At least one photo required"
    );
  }

  // ── Duplicate photo detection (pHash) ────────────────────────
  const seventyTwoHoursAgo = new Date(Date.now() - 72 * 60 * 60 * 1000);
  const recentReports = await db
    .collection("reports")
    .where("reporterId", "==", userId)
    .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(seventyTwoHoursAgo))
    .get();

  // Note: In production, download the image and compute pHash
  // For now, store URL hash for comparison
  const duplicateFlag =
    recentReports.docs.some((doc) =>
      (doc.data().photoUrls as string[]).some((url) =>
        photoUrls.includes(url)
      )
    );

  if (duplicateFlag) {
    throw new functions.https.HttpsError(
      "already-exists",
      "Duplicate photo detected. Please submit a fresh photo."
    );
  }

  // ── AI Classification (Groq Vision) ─────────────────────────
  const { label: aiLabel, severity } = await classifyImage(photoUrls[0]);

  // ── Firestore write ──────────────────────────────────────────
  return db.runTransaction(async (tx) => {
    const reportRef = db.collection("reports").doc();
    const walletRef = db.collection("wallets").doc(userId);
    const spotRef = db.collection("spots").doc(spotId);

    const wallet = await tx.get(walletRef);
    const wData = wallet.data() ?? {};

    // Write report
    tx.set(reportRef, {
      spotId,
      reporterId: userId,
      photoUrls,
      issueType,
      description,
      aiLabel,
      severity,
      status: "open",
      geopoint: new admin.firestore.GeoPoint(lat, lng),
      createdAt: now,
      assignedTo: "",
      resolvedAt: null,
      pointsEarned: REPORT_POINTS,
      isValid: true,
    });

    // Update spot status
    const newSpotStatus =
      severity === "high" ?
        "critical" :
        severity === "medium" ?
          "issue" :
          "issue";

    tx.update(spotRef, {
      status: newSpotStatus,
      lastReportedAt: now,
    });

    // Award points
    const newBalance = (wData.balance as number ?? 0) + REPORT_POINTS;
    const newLifetime = (wData.lifetimeEarned as number ?? 0) + REPORT_POINTS;
    tx.update(walletRef, {
      balance: newBalance,
      lifetimeEarned: newLifetime,
      totalReports: admin.firestore.FieldValue.increment(1),
    });

    // Update leaderboard
    const lbRef = db.collection("leaderboard").doc(userId);
    tx.update(lbRef, {
      weekPoints: admin.firestore.FieldValue.increment(REPORT_POINTS),
      monthPoints: admin.firestore.FieldValue.increment(REPORT_POINTS),
      allTimePoints: admin.firestore.FieldValue.increment(REPORT_POINTS),
    });

    // Notify municipal officers via FCM topic
    try {
      await messaging.send({
        topic: "municipal_alerts",
        notification: {
          title: `New ${severity.toUpperCase()} Priority Issue`,
          body: `${aiLabel} — ${issueType} reported near ${lat.toFixed(4)}, ${lng.toFixed(4)}`,
        },
        data: {
          reportId: reportRef.id,
          spotId,
          severity,
          lat: lat.toString(),
          lng: lng.toString(),
        },
      });
    } catch (fcmError) {
      functions.logger.warn("FCM send failed:", fcmError);
    }

    functions.logger.info(
      `Report created: ${reportRef.id} severity=${severity} label="${aiLabel}"`
    );

    return {
      reportId: reportRef.id,
      pointsEarned: REPORT_POINTS,
      aiLabel,
      severity,
    };
  });
});

// ── Firestore trigger: onStatusChange ──────────────────────────
export const onReportStatusChange = functions.firestore
  .document("reports/{reportId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return null; // No change

    const { reportId } = ctx.params;
    const reporterId: string = after.reporterId;

    if (after.status === "resolved") {
      // Award bonus to reporter
      const walletRef = db.collection("wallets").doc(reporterId);
      const lbRef = db.collection("leaderboard").doc(reporterId);

      await db.runTransaction(async (tx) => {
        const wallet = await tx.get(walletRef);
        const bal = wallet.data()?.balance ?? 0;
        const lf = wallet.data()?.lifetimeEarned ?? 0;
        const badges: string[] = wallet.data()?.badges ?? [];

        if (!badges.includes("🏆 Issue Resolver")) {
          badges.push("🏆 Issue Resolver");
        }

        tx.update(walletRef, {
          balance: bal + RESOLVED_BONUS,
          lifetimeEarned: lf + RESOLVED_BONUS,
          badges,
        });
        tx.update(lbRef, {
          weekPoints: admin.firestore.FieldValue.increment(RESOLVED_BONUS),
          monthPoints: admin.firestore.FieldValue.increment(RESOLVED_BONUS),
          allTimePoints: admin.firestore.FieldValue.increment(RESOLVED_BONUS),
        });
        // Mark resolved timestamp
        tx.update(change.after.ref, {
          resolvedAt: admin.firestore.Timestamp.now(),
        });
      });

      // Send push to reporter
      const tokenDoc = await db
        .collection("fcmTokens")
        .doc(reporterId)
        .get();
      const token = tokenDoc.data()?.token;
      if (token) {
        await messaging.send({
          token,
          notification: {
            title: "Issue Resolved! 🎉",
            body: `Your report was resolved. +${RESOLVED_BONUS} bonus points added!`,
          },
        });
      }

      functions.logger.info(
        `Report ${reportId} resolved — +${RESOLVED_BONUS}pts to ${reporterId}`
      );
    }

    return null;
  });
