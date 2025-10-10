import admin from "firebase-admin";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
admin.initializeApp();
const db = admin.firestore();

export const messageNotification = onDocumentCreated(
  "/messages/{sku}",
  (event) => {
    const data = event.data?.data();
    if (!data) return;
    const matchId: string = data.matchId;
    const senderId: string = data.senderId;
    const message: string = data.type === "text" ? data.text : "Audio";
    return db
      .collection("matches")
      .doc(matchId)
      .get()
      .then((doc) => {
        const data = doc.data();
        if (!data) return;
        const users: string[] = data.users;
        const receiveUser = users.find((u) => u !== senderId);
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
            const multicastMessage: MulticastMessage = {
              tokens: pushTokens,
              notification: {
                title: `Message from ${senderId}`,
              },
            };
            if (message) {
              multicastMessage.data = {
                matchId: matchId,
                type: "chat",
              };
              multicastMessage.notification!.body = message;
            }
            return getMessaging()
              .sendEachForMulticast(multicastMessage)
              .then((response) => {
                if (response.failureCount > 0) {
                  const failedTokens: string[] = [];
                  response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                      failedTokens.push(pushTokens[idx]);
                      console.log(resp.error?.message);
                    }
                  });
                  console.log(
                    "List of tokens that caused failures: " + failedTokens
                  );
                }
                return response;
              });
          });
      });
  }
);
