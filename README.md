# 📍 SpotSeva — Adopt a Spot

> **Gamified civic maintenance** for Greater Noida. Citizens adopt public spaces, check in daily, report issues with AI-classified photos, and earn real rewards from local businesses.

---

## 🗂 Project Structure

```
SpotSeva/
├── adopt_a_spot/          # Flutter mobile app (Android/iOS)
├── dashboard/             # Flutter Web — Municipal Command Centre
├── functions/             # Firebase Cloud Functions (TypeScript)
├── firestore.rules        # Firestore security rules
├── firestore.indexes.json # Composite indexes
├── storage.rules          # Firebase Storage rules
├── firebase.json          # Firebase project config
└── .github/workflows/     # CI/CD pipeline
```

---

## ✅ Features

### Mobile App (Flutter)
| Feature | Detail |
|---|---|
| 🗺 **OpenStreetMap** | flutter_map + clustered markers, 100m proximity ring |
| 📌 **Adopt a Spot** | 1 spot per citizen, +50 pts, Firestore atomic transaction |
| ✅ **Daily Check-in** | GPS validation (100m), 2/day limit, 3h gap, streak counter |
| 🔥 **Streak Bonuses** | +50 pts on 7-day streak, +200 pts on 30-day streak |
| 📸 **Report Issues** | Camera/gallery, compress→upload, Groq Vision AI classification |
| 🏆 **Leaderboard** | Weekly/monthly/all-time, real-time stream |
| 🎁 **Rewards Store** | Redeem points for local coupons, QR code display |
| 🏅 **Badges** | Automatic badge grants on milestones |
| 🔔 **Push Notifications** | FCM — new reports, issue resolved |

### Municipal Dashboard (Flutter Web)
| Screen | Feature |
|---|---|
| **Overview** | Real-time KPI cards, OSM heatmap, priority queue, activity feed |
| **Report Queue** | Filter by status/severity, photo thumbnails, detail panel, 1-click status update |
| **Field Workers** | Add/remove workers, assignment tracking |
| **Spot Manager** | Add spots with lat/lng (auto-geohash), filter by status |
| **Analytics** | 4 live charts: reports bar, severity pie, check-ins line, top spots |
| **Citizens** | Leaderboard table with search, flagged user detection, unflag action |

### Cloud Functions (TypeScript)
| Function | Type | Purpose |
|---|---|---|
| `onUserCreate` | Auth trigger | Init wallet + profile + leaderboard entry |
| `adoptSpot` | Callable | Atomic adopt with 1-spot limit |
| `releaseSpot` | Callable | Release spot back to pool |
| `checkIn` | Callable | GPS check + streak + points (atomic) |
| `submitReport` | Callable | Groq Vision AI + pHash duplicate check + FCM alert |
| `onReportStatusChange` | Firestore trigger | +50 bonus on resolved, push to reporter |
| `redeemCoupon` | Callable | Atomic balance deduct + UUID coupon |
| `detectSuspiciousActivity` | Scheduled (6h) | Flag >10 check-ins/6h, auto-release stale spots |
| `computeLeaderboard` | Scheduled (1h) | Recompute weekly/monthly points |
| `seedSpots` | HTTP | One-time seed 20 spots + 5 rewards (dev only) |

---

## 🚀 Setup Guide

### Prerequisites
```
- Flutter 3.22+
- Node.js 20+
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)
```

### 1. Clone & Firebase Setup
```bash
git clone <repo-url>
cd SpotSeva

# Login to Firebase
firebase login

# Create Firebase project at console.firebase.google.com
# Enable: Authentication (Google), Firestore, Storage, Functions, Cloud Messaging
firebase use --add   # select your project
```

### 2. FlutterFire Configuration (Mobile App)
```bash
cd adopt_a_spot
flutterfire configure --project=<your-project-id>
# This auto-generates lib/firebase_options.dart
flutter pub get
```

### 3. FlutterFire Configuration (Dashboard)
```bash
cd ../dashboard
flutterfire configure --project=<your-project-id>
# Update dashboard/lib/main.dart with generated FirebaseOptions
flutter pub get
```

### 4. Configure Groq API Key
```bash
cd ../functions
# Set your Groq API key (get free at console.groq.com)
firebase functions:config:set groq.api_key="gsk_YOUR_GROQ_KEY" app.env="production"

# Or for emulator, create .env.local:
echo 'GROQ_API_KEY=gsk_YOUR_GROQ_KEY' > .env.local
```

### 5. Deploy Firestore Rules & Indexes
```bash
cd ..
firebase deploy --only firestore
firebase deploy --only storage
```

### 6. Deploy Cloud Functions
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### 7. Seed Initial Data (20 Greater Noida Spots + 5 Rewards)
```bash
# After deploying, call the seed endpoint ONCE:
curl https://<region>-<project-id>.cloudfunctions.net/seedSpots
# Or via Firebase Functions Shell:
firebase functions:shell
> seedSpots.get()
```

### 8. Run Mobile App
```bash
cd adopt_a_spot
flutter run                          # Debug on connected device
flutter run --release                # Release build
flutter build apk --release          # Generate APK
```

### 9. Run Dashboard Locally
```bash
cd dashboard
flutter run -d chrome --web-renderer canvaskit
flutter build web --release          # Production build
```

### 10. Run Emulators (Development)
```bash
# Terminal 1: Start all emulators
firebase emulators:start

# Terminal 2: Run mobile app pointing to emulators
cd adopt_a_spot
flutter run --dart-define=USE_EMULATOR=true
```

---

## 🔐 Security

| Rule | Detail |
|---|---|
| Wallets | **No direct client writes** — only Cloud Functions can award points |
| Spots | Public read, municipal-only write |
| Reports | Created via Cloud Function only, municipal can update status |
| Leaderboard | Read-only for clients |
| Storage | 5MB limit, image/* only, user-scoped upload |

---

## 🤖 AI Photo Classification

Uses **Groq API** (`llama-3.2-11b-vision-preview`) for zero-cost, fast vision inference:
- Classifies issue type from photo
- Returns `{ label, severity }` — severity drives spot status update
- Falls back gracefully if API unavailable

---

## 📦 Required GitHub Secrets (for CI/CD)

| Secret | Value |
|---|---|
| `FIREBASE_TOKEN` | `firebase login:ci` output |
| `FIREBASE_PROJECT_ID` | Your Firebase project ID |
| `CODECOV_TOKEN` | Codecov upload token (optional) |

---

## 📊 Data Schema (Firestore)

```
spots/{spotId}         — geopoint, geohash, status, adopterId, checkinsCount
reports/{reportId}     — spotId, photoUrls, aiLabel, severity, status, geopoint
checkins/{checkinId}   — userId, spotId, timestamp, lat, lng, pointsEarned
wallets/{userId}       — balance, lifetimeEarned, streak, badges, totalReports
users/{userId}         — displayName, role, adoptedSpotId, flagged
leaderboard/{userId}   — weekPoints, monthPoints, allTimePoints
rewards/{rewardId}     — pointsCost, totalQty, redeemedQty, expiresAt
redemptions/{id}       — userId, couponCode, used
fcmTokens/{userId}     — token
```

---

## 📝 Legal

- Data stored per **DPDP Act 2023** — deletion within 30 days on request
- Location data used only for proximity validation, not tracked persistently
- OSM tiles: [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright)

---

*Built by Shashvat — Greater Noida Ward 14 Pilot, 2025*
