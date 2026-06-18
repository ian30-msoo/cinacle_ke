const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");

initializeApp();

exports.cleanupExpiredStatuses = onSchedule(
    {
      schedule: "every 30 minutes",
      timeZone: "Etc/UTC",
    },
    async () => {
      const db = getFirestore();
      const now = Timestamp.now();

      const expiredSnap = await db
          .collection("statuses")
          .where("expiresAt", "<=", now)
          .get();

      if (expiredSnap.empty) {
        console.log("No expired statuses to clean up.");
        return;
      }

      const bucket = getStorage().bucket();
      const batchSize = 400;
      let batch = db.batch();
      let opsInBatch = 0;
      let deletedCount = 0;

      for (const doc of expiredSnap.docs) {
        const data = doc.data();

        if (data.imageUrl) {
          try {
            const path = decodeURIComponent(
                new URL(data.imageUrl).pathname
                    .split("/o/")[1]
                    .split("?")[0],
            );
            await bucket.file(path).delete({ignoreNotFound: true});
          } catch (err) {
            console.warn(
                `Could not delete image for status ${doc.id}:`,
                err.message,
            );
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
    },
);
