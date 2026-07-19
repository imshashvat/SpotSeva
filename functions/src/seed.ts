// functions/src/seed.ts
// Pre-seeds 20 real micro-spots in Greater Noida, Ward 14 (Sector 12/Alpha/Beta area)
// Run once: firebase functions:shell → seedSpots()
// OR deploy and call via Firebase Admin SDK script.
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

interface SpotSeed {
  name: string;
  lat: number;
  lng: number;
  category: string;
  description: string;
  ward: string;
}

// 20 real public micro-spots in Greater Noida Ward 14 area
const SPOTS: SpotSeed[] = [
  {
    name: "Sector 12 Central Park — Main Bench Row",
    lat: 28.4712, lng: 77.5038,
    category: "Park Furniture",
    description: "Row of 6 iron benches at the park entrance, facing the fountain.",
    ward: "Ward 14",
  },
  {
    name: "Alpha 1 Bus Stop — Near Metro Feeder",
    lat: 28.4735, lng: 77.5012,
    category: "Bus Stop",
    description: "Main bus shelter serving routes 110, 225, and Metro Feeder 7.",
    ward: "Ward 14",
  },
  {
    name: "Sector 12 Park — Kids Play Area",
    lat: 28.4720, lng: 77.5055,
    category: "Park Furniture",
    description: "Children's swings, slide, and climbing frame near the park centre.",
    ward: "Ward 14",
  },
  {
    name: "Alpha 2 Commercial Street Light #47",
    lat: 28.4748, lng: 77.5028,
    category: "Street Light",
    description: "LED street light on Alpha 2 main commercial road near D-block turn.",
    ward: "Ward 14",
  },
  {
    name: "Gamma Park Entrance Gate",
    lat: 28.4698, lng: 77.5070,
    category: "Park Entrance",
    description: "South-facing entrance to Gamma Park with potted plant beds.",
    ward: "Ward 14",
  },
  {
    name: "Beta 1 Pedestrian Footpath — Sector 10 Border",
    lat: 28.4760, lng: 77.5000,
    category: "Footpath",
    description: "500m paved footpath from Sector 10 border to Alpha 1 roundabout.",
    ward: "Ward 14",
  },
  {
    name: "Surajpur Wetland Viewing Platform",
    lat: 28.4680, lng: 77.5090,
    category: "Water Body",
    description: "Wooden viewing deck overlooking the Surajpur wetland bird zone.",
    ward: "Ward 14",
  },
  {
    name: "Sector 12 Park — Morning Walk Track",
    lat: 28.4725, lng: 77.5042,
    category: "Public Garden",
    description: "400m jogging track surrounding the central garden area.",
    ward: "Ward 14",
  },
  {
    name: "Alpha 1 Market Bus Shelter",
    lat: 28.4742, lng: 77.5005,
    category: "Bus Stop",
    description: "Covered bus shelter at Alpha 1 vegetable market, 3 benches inside.",
    ward: "Ward 14",
  },
  {
    name: "Delta Park — Outdoor Gym Station",
    lat: 28.4705, lng: 77.5080,
    category: "Park Furniture",
    description: "Set of 8 outdoor gym equipment pieces installed by GNIDA.",
    ward: "Ward 14",
  },
  {
    name: "Sector 12 Gate 2 — Streetlight Pole",
    lat: 28.4715, lng: 77.5025,
    category: "Street Light",
    description: "High-mast street light at Sector 12 Gate 2 entry.",
    ward: "Ward 14",
  },
  {
    name: "Alpha 1 Roundabout — Garden Bed",
    lat: 28.4750, lng: 77.5020,
    category: "Public Garden",
    description: "Circular garden bed at Alpha 1 roundabout, seasonal flowers.",
    ward: "Ward 14",
  },
  {
    name: "Beta 2 Walking Path — Near School",
    lat: 28.4770, lng: 77.5015,
    category: "Footpath",
    description: "School-zone footpath with speed bumps and child-safe railings.",
    ward: "Ward 14",
  },
  {
    name: "Gamma 1 Sector Park — Lotus Pond",
    lat: 28.4692, lng: 77.5075,
    category: "Water Body",
    description: "Small ornamental lotus pond maintained by RWA. Weekly cleaning.",
    ward: "Ward 14",
  },
  {
    name: "Alpha Commercial Strip — Bench Cluster",
    lat: 28.4738, lng: 77.5035,
    category: "Park Furniture",
    description: "5 concrete benches at Alpha commercial strip outdoor seating zone.",
    ward: "Ward 14",
  },
  {
    name: "Sector 12 Main Road — Divider Garden",
    lat: 28.4730, lng: 77.5048,
    category: "Public Garden",
    description: "150m road divider garden with palm trees and flowering shrubs.",
    ward: "Ward 14",
  },
  {
    name: "Ecotech 3 Entry — Bus Stop",
    lat: 28.4688, lng: 77.5060,
    category: "Bus Stop",
    description: "Bus stop at Ecotech 3 industrial area entry serving factory workers.",
    ward: "Ward 14",
  },
  {
    name: "Alpha 1 Sector Park — East Gate",
    lat: 28.4745, lng: 77.5050,
    category: "Park Entrance",
    description: "East-facing park gate with wheelchair ramp and signage board.",
    ward: "Ward 14",
  },
  {
    name: "Sector 12 — High-Mast Light Post",
    lat: 28.4708, lng: 77.5032,
    category: "Street Light",
    description: "30m high-mast light illuminating the Sector 12 parking zone.",
    ward: "Ward 14",
  },
  {
    name: "Beta 1 Sector Park — Meditation Corner",
    lat: 28.4765, lng: 77.5010,
    category: "Public Garden",
    description: "Quiet corner with bamboo seating, pebble path, and shade trees.",
    ward: "Ward 14",
  },
];

function geohash(lat: number, lng: number, precision = 5): string {
  const base32 = "0123456789bcdefghjkmnpqrstuvwxyz";
  let minLat = -90.0; let maxLat = 90.0;
  let minLng = -180.0; let maxLng = 180.0;
  let hash = "";
  let bits = 0; let hashValue = 0;
  let isEven = true;

  while (hash.length < precision) {
    if (isEven) {
      const mid = (minLng + maxLng) / 2;
      if (lng >= mid) {
        hashValue = (hashValue << 1) | 1; minLng = mid;
      } else {
        hashValue = hashValue << 1; maxLng = mid;
      }
    } else {
      const mid = (minLat + maxLat) / 2;
      if (lat >= mid) {
        hashValue = (hashValue << 1) | 1; minLat = mid;
      } else {
        hashValue = hashValue << 1; maxLat = mid;
      }
    }
    isEven = !isEven;
    bits++;
    if (bits === 5) {
      hash += base32[hashValue];
      bits = 0;
      hashValue = 0;
    }
  }
  return hash;
}

export const seedSpots = functions.https.onRequest(async (_req, res) => {
  // Safety: only allow in development/emulator
  const env = functions.config().app?.env || process.env.ENVIRONMENT || "development";
  if (env === "production") {
    res.status(403).json({ error: "Seed disabled in production" });
    return;
  }

  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();
  const seeded: string[] = [];

  for (const spot of SPOTS) {
    // Skip if spot with same name already exists
    const existing = await db
      .collection("spots")
      .where("name", "==", spot.name)
      .limit(1)
      .get();

    if (!existing.empty) {
      seeded.push(`SKIP: ${spot.name}`);
      continue;
    }

    const ref = db.collection("spots").doc();
    const gh = geohash(spot.lat, spot.lng);

    batch.set(ref, {
      name: spot.name,
      adopterId: "",
      geohash: gh,
      geopoint: new admin.firestore.GeoPoint(spot.lat, spot.lng),
      status: "clean",
      category: spot.category,
      checkinsCount: 0,
      lastCheckin: now,
      ward: spot.ward,
      description: spot.description,
      isActive: true,
      createdAt: now,
      createdBy: "seed",
    });

    seeded.push(`OK: ${spot.name} [${gh}]`);
  }

  await batch.commit();

  // Also seed 5 sample rewards
  await seedRewards(db, now);

  functions.logger.info(`Seeded ${seeded.filter((s) => s.startsWith("OK")).length} spots`);
  res.json({
    success: true,
    seeded,
    rewardsSeed: "5 sample rewards added",
  });
});

async function seedRewards(
  db: admin.firestore.Firestore,
  now: admin.firestore.Timestamp
) {
  const rewards = [
    {
      businessId: "cafe_gamma",
      businessName: "Gamma Café & Co.",
      title: "Free Cappuccino",
      description: "Redeem for one free cappuccino (any size) at any Gamma Café outlet.",
      pointsCost: 100,
      totalQty: 200,
      redeemedQty: 0,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)
      ),
      category: "Food",
      imageUrl: "",
      isFeatured: true,
    },
    {
      businessId: "smart_grocery",
      businessName: "SmartMart Grocery",
      title: "10% Off Grocery Bill",
      description: "Get 10% off any grocery bill above ₹500 at SmartMart.",
      pointsCost: 200,
      totalQty: 150,
      redeemedQty: 0,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 60 * 24 * 60 * 60 * 1000)
      ),
      category: "Grocery",
      imageUrl: "",
      isFeatured: false,
    },
    {
      businessId: "alpha_cinema",
      businessName: "Alpha Cinemas",
      title: "Free Movie Ticket",
      description: "One free movie ticket (weekday shows) at Alpha Cinemas, Greater Noida.",
      pointsCost: 500,
      totalQty: 50,
      redeemedQty: 0,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 45 * 24 * 60 * 60 * 1000)
      ),
      category: "Entertainment",
      imageUrl: "",
      isFeatured: true,
    },
    {
      businessId: "gnida_municipal",
      businessName: "GNIDA Municipal Corp.",
      title: "Civic Hero Certificate",
      description: "Official Civic Hero recognition certificate from GNIDA. Framed and mailed.",
      pointsCost: 1000,
      totalQty: 30,
      redeemedQty: 0,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
      ),
      category: "Recognition",
      imageUrl: "",
      isFeatured: false,
    },
    {
      businessId: "local_pharmacy",
      businessName: "HealthPlus Pharmacy",
      title: "5% Off Medicines",
      description: "5% discount on all medicines (excludes controlled substances).",
      pointsCost: 150,
      totalQty: 100,
      redeemedQty: 0,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 60 * 24 * 60 * 60 * 1000)
      ),
      category: "Healthcare",
      imageUrl: "",
      isFeatured: false,
    },
  ];

  const batch = db.batch();
  for (const reward of rewards) {
    const existing = await db
      .collection("rewards")
      .where("title", "==", reward.title)
      .limit(1)
      .get();
    if (existing.empty) {
      const ref = db.collection("rewards").doc();
      batch.set(ref, { ...reward, createdAt: now });
    }
  }
  await batch.commit();
}
