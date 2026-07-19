// functions/src/photoHash.ts — perceptual hash (pHash) duplicate detection
import * as functions from "firebase-functions";
import Jimp from "jimp";

/**
 * Compute a 32x32 average-hash of an image buffer.
 * Returns a binary string of 0/1 characters.
 */
export async function computePHash(imageBuffer: Buffer): Promise<string> {
  try {
    const img = await Jimp.read(imageBuffer);
    img.resize(32, 32).greyscale();
    const pixels: number[] = [];
    img.scan(0, 0, 32, 32, (_x, _y, idx) => {
      // Jimp stores RGBA — use R channel for greyscale
      pixels.push(img.bitmap.data[idx]);
    });
    const avg = pixels.reduce((a, b) => a + b, 0) / pixels.length;
    return pixels.map((p) => (p >= avg ? "1" : "0")).join("");
  } catch (e) {
    functions.logger.warn("pHash computation failed:", e);
    return "";
  }
}

/**
 * Hamming distance between two binary hash strings.
 * Distance < 10 → considered duplicate.
 */
export function hammingDistance(a: string, b: string): number {
  if (a.length !== b.length) return Number.MAX_SAFE_INTEGER;
  let dist = 0;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) dist++;
  }
  return dist;
}

/**
 * Check whether a new pHash is a duplicate of any in an existing list.
 * Returns true if it IS a duplicate.
 */
export function isDuplicate(
  newHash: string,
  existingHashes: string[],
  threshold = 10
): boolean {
  return existingHashes.some(
    (h) => hammingDistance(newHash, h) < threshold
  );
}
