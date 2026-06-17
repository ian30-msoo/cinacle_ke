/**
 * Scheduled Cloud Function: deletes status documents whose expiresAt
 * has passed. Run alongside (not instead of) a Firestore TTL policy on
 * the `expiresAt` field — TTL handles eventual deletion automatically,
 * but its deletion latency isn't guaranteed (can take up to ~24h after
 * expiry in some cases), so this function gives you a tighter, predictable
 * cleanup window and a place to add side effects (e.g. deleting the
 * matching image from Storage) when a status is removed.
 *
 * Setup:
 *   npm install firebase-functions firebase-admin
 *   firebase deploy --only functions:cleanupExpiredStatuses
 *
 * Requires Firebase Functions v2 (scheduler) — adjust if you're on v1.
 */

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

initializeApp();

exports.cleanupExpiredStatuses = onSchedule(
  {
    schedule: 'every 30 minutes',
    timeZone: 'Etc/UTC',
  },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();

    const expiredSnap = await db
      .collection('statuses')
      .where('expiresAt', '<=', now)
      .get();

    if (expiredSnap.empty) {
      console.log('No expired statuses to clean up.');
      return;
    }

    const bucket = getStorage().bucket();
    const batchSize = 400; // stay under Firestore's 500-op batch limit
    let batch = db.batch();
    let opsInBatch = 0;
    let deletedCount = 0;

    for (const doc of expiredSnap.docs) {
      const data = doc.data();

      // Best-effort: remove the associated Storage image, if any.
      if (data.imageUrl) {
        try {
          const path = decodeURIComponent(
            new URL(data.imageUrl).pathname.split('/o/')[1].split('?')[0]
          );
          await bucket.file(path).delete({ ignoreNotFound: true });
        } catch (err) {
          console.warn(`Could not delete image for status ${doc.id}:`, err.message);
        }
      }

      batch.delete(doc.ref);
      opsInBatch++;
      deletedCount++;

      if (opsInBatch >= batchSize) {
        await batch.commit();
        batch = db.batch();
        opsInBatch = 0;
      }
    }

    if (opsInBatch > 0) {
      await batch.commit();
    }

    console.log(`Cleaned up ${deletedCount} expired status(es).`);
  }
);