import admin from "firebase-admin";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
admin.initializeApp();
const db = admin.firestore();
logger.info("Trigger ok");

export const test = onDocumentCreated(
  {
    document: "_test/{sku}",
    region: "asia-southeast1",
  },
  (event) => {
    logger.log(`It worked: [${event.params.sku}]`);
    return Promise.resolve();
  }
);

export const messageNotification = onDocumentCreated(
  {
    document: "messages/{sku}",
    region: "asia-southeast1",
  },
  (event) => {
    const data = event.data?.data();
    if (!data) return;
    logger.log(`We got new message: [${data}]`);
    const matchId: string = data.matchId;
    const senderId: string = data.senderId;
    const message: string =
      data.type === "text" ? data.text : "Tin nhắn mới qua âm thanh";
    return db
      .collection("matches")
      .doc(matchId)
      .get()
      .then((doc) => {
        const data = doc.data();
        if (!data) return;
        const users: string[] = data.users;
        const receiveUser = users.find((u) => u !== senderId);
        logger.log(`We got receiveUser: ${receiveUser}`);
        if (!receiveUser) return;

        return db
          .collection("users")
          .doc(receiveUser)
          .get()
          .then((doc) => {
            const data = doc.data();
            if (!data) return;
            const pushTokens: string[] = data.pushTokens;
            if (!pushTokens) return;
            logger.log("Pushing tokens to user");
            const multicastMessage: MulticastMessage = {
              tokens: pushTokens,
              notification: {
                title: `Message from ${senderId}`,
                body: message,
              },
            };
            if (message) {
              multicastMessage.data = {
                matchId: matchId,
                type: "chat",
              };
            }
            return getMessaging()
              .sendEachForMulticast(multicastMessage)
              .then((response) => {
                if (response.failureCount > 0) {
                  const failedTokens: string[] = [];
                  response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                      failedTokens.push(pushTokens[idx]);
                      logger.log(resp.error?.message);
                    }
                  });
                  logger.log(
                    "List of tokens that caused failures: " + failedTokens
                  );
                }
                return response;
              });
          });
      });
  }
);
