// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  // ── Firestore Collections ─────────────────────────────────────
  static const colSpots = 'spots';
  static const colReports = 'reports';
  static const colCheckins = 'checkins';
  static const colWallets = 'wallets';
  static const colUsers = 'users';
  static const colRewards = 'rewards';
  static const colRedemptions = 'redemptions';
  static const colLeaderboard = 'leaderboard';
  static const colFcmTokens = 'fcmTokens';

  // ── Roles ─────────────────────────────────────────────────────
  static const roleCitizen = 'citizen';
  static const roleMunicipal = 'municipal';
  static const roleFieldWorker = 'field_worker';

  // ── Status values ─────────────────────────────────────────────
  static const statusOpen = 'open';
  static const statusInProgress = 'inProgress';
  static const statusResolved = 'resolved';
  static const statusRejected = 'rejected';

  // ── Map & Geo ─────────────────────────────────────────────────
  // Default center: Sector 12, Greater Noida, Ward 14
  static const defaultLat = 28.4744;
  static const defaultLng = 77.5040;
  static const defaultZoom = 15.0;
  static const checkInRadiusMeters = 100.0;
  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // ── Points ────────────────────────────────────────────────────
  static const pointsAdopt = 50;
  static const pointsCheckin = 10;
  static const pointsReport = 25;
  static const pointsResolved = 50;
  static const pointsStreak7 = 50;
  static const pointsStreak30 = 200;

  // ── Leaderboard ───────────────────────────────────────────────
  static const leaderboardTopN = 50;

  // ── Issue categories ──────────────────────────────────────────
  static const issueCategories = [
    'Litter / Garbage',
    'Broken Furniture',
    'Graffiti / Vandalism',
    'Street Light Out',
    'Waterlogging',
    'Overgrown Plants',
    'Safety Hazard',
    'Fallen Tree',
    'Damaged Road',
    'Other',
  ];

  // ── Spot categories ───────────────────────────────────────────
  static const spotCategories = [
    'Park Furniture',
    'Bus Stop',
    'Street Light',
    'Public Garden',
    'Footpath',
    'Water Body',
    'Park Entrance',
  ];

  // ── Colours (hex int values, use with Color(AppConstants.colorXxx)) ──
  static const colorTeal   = 0xFF0F6E56;
  static const colorBlue   = 0xFF1A5FAD;
  static const colorGreen  = 0xFF2E7D52;
  static const colorAmber  = 0xFFAA6C00;
  static const colorRed    = 0xFFA32D2D;
  static const colorCoral  = 0xFFBF4B32;
  static const colorPurple = 0xFF6B21A8;

  // ── Anti-fraud thresholds ─────────────────────────────────────
  static const maxCheckinsPerDay = 2;
  static const minHoursBetweenCheckins = 3;
  static const staleSpotDays = 7;

  // ── Storage paths ─────────────────────────────────────────────
  static const storageReports = 'reports';
  static const storageAvatars = 'avatars';
}
