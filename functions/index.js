const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// STATUS CLEANUP
exports.cleanupExpiredStatuses = onSchedule(
    {
      schedule: "every 30 minutes",
      timeZone: "Etc/UTC",
    },
    async () => {
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

// MESSAGE / REPLY NOTIFICATIONS

async function getRecipientTokens(memberIds, excludeUserId) {
  const recipients = memberIds.filter((id) => id !== excludeUserId);
  const tokens = [];

  for (const uid of recipients) {
    const userDoc = await db.doc(`users/${uid}`).get();
    const token = userDoc.data()?.fcmToken;
    if (token) tokens.push(token);
  }

  return tokens;
}

// Triggered when someone sends a message inside a private room.
exports.onRoomMessageCreated = onDocumentCreated(
    "private_rooms/{roomId}/messages/{messageId}",
    async (event) => {
      const message = event.data.data();
      const {roomId} = event.params;

      const roomSnap = await db.doc(`private_rooms/${roomId}`).get();
      const room = roomSnap.data();
      if (!room) return;

      const tokens = await getRecipientTokens(
          room.memberIds || [],
          message.senderId,
      );
      if (tokens.length === 0) return;

      await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: message.senderName || "New message",
          body: message.text || "",
        },
        data: {conversationId: roomId},
      });
    },
);

// Triggered when someone replies to a Let's Talk post.
exports.onPostReplyCreated = onDocumentCreated(
    "lets_talk_posts/{postId}/replies/{replyId}",
    async (event) => {
      const reply = event.data.data();
      const {postId} = event.params;

      const postSnap = await db.doc(`lets_talk_posts/${postId}`).get();
      const post = postSnap.data();
      if (!post) return;

      // Only the original poster gets notified here
      if (!post.authorId || post.authorId === reply.senderId) return;

      const userDoc = await db.doc(`users/${post.authorId}`).get();
      const token = userDoc.data()?.fcmToken;
      if (!token) return;

      await getMessaging().send({
        token,
        notification: {
          title: `${reply.senderName || "Someone"} replied to your post`,
          body: reply.text || "",
        },
        data: {conversationId: postId},
      });
    },
);