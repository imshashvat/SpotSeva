// functions/src/index.ts — Cloud Function exports
export { onUserCreate } from "./auth";
export { adoptSpot, releaseSpot } from "./spots";
export { checkIn } from "./checkins";
export { submitReport, onReportStatusChange } from "./reports";
export { redeemCoupon } from "./rewards";
export { detectSuspiciousActivity } from "./antifraud";
export { computeLeaderboard } from "./leaderboard";
export { seedSpots } from "./seed";
