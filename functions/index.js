
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function: Triggered when a new expense document is created.
 * Sends FCM push notifications to all group members.
 */
exports.onExpenseCreated = functions.firestore
  .document("expenses/{expenseId}")
  .onCreate(async (snap, context) => {
    const expense = snap.data();
    const { groupId, title, amount, currency, createdBy } = expense;

    // Fetch group to get member FCM tokens
    const groupDoc = await admin.firestore().collection("groups").doc(groupId).get();
    if (!groupDoc.exists) return;

    const members = groupDoc.data().members || [];
    const creatorDoc = await admin.firestore().collection("users").doc(createdBy).get();
    const creatorName = creatorDoc.exists ? creatorDoc.data().displayName : "Someone";

    const tokens = [];
    for (const member of members) {
      if (member.userId !== createdBy) {
        const userDoc = await admin.firestore().collection("users").doc(member.userId).get();
        if (userDoc.exists && userDoc.data().fcmToken) {
          tokens.push(userDoc.data().fcmToken);
        }
      }
    }

    if (tokens.length === 0) return;

    const message = {
      notification: {
        title: `New expense in your group`,
        body: `${creatorName} added "${title}" for ${currency} ${parseFloat(amount).toFixed(2)}`,
      },
      data: {
        type: "new_expense",
        groupId,
        expenseId: context.params.expenseId,
      },
      tokens,
    };

    await admin.messaging().sendEachForMulticast(message);
  });

/**
 * Cloud Function: Triggered when a settlement is recorded.
 * Notifies the recipient.
 */
exports.onSettlementCreated = functions.firestore
  .document("settlements/{settlementId}")
  .onCreate(async (snap) => {
    const settlement = snap.data();
    const { toUserId, fromUserId, amount, currency } = settlement;

    const [fromDoc, toDoc] = await Promise.all([
      admin.firestore().collection("users").doc(fromUserId).get(),
      admin.firestore().collection("users").doc(toUserId).get(),
    ]);

    if (!toDoc.exists || !toDoc.data().fcmToken) return;

    const fromName = fromDoc.exists ? fromDoc.data().displayName : "Someone";

    await admin.messaging().send({
      notification: {
        title: "Payment received!",
        body: `${fromName} paid you ${currency} ${parseFloat(amount).toFixed(2)}`,
      },
      data: { type: "settlement", fromUserId },
      token: toDoc.data().fcmToken,
    });
  });