"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { computeNetBalances, buildDigest } = require("./lib/balances");

admin.initializeApp();
const db = admin.firestore();

const INVITE_CODE_RE = /^[A-Z0-9]{6,16}$/;

/** Reads the owner-only push token stored at users/{uid}/private/push. */
async function getFcmToken(uid) {
  const snap = await db.doc(`users/${uid}/private/push`).get();
  return snap.exists ? snap.data().fcmToken || null : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Push delivery
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Every in-app notification (new expense, settlement, nudge, member events…)
 * is a document under users/{uid}/notifications. Pushing from that single
 * place keeps the push and the in-app inbox in sync and avoids duplicates.
 * Preference / mute filtering already happened when the client wrote it.
 */
exports.onNotificationCreated = functions.firestore
  .document("users/{userId}/notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const { userId, notifId } = context.params;
    const n = snap.data();

    const token = await getFcmToken(userId);
    if (!token) return null;

    try {
      await admin.messaging().send({
        token,
        notification: { title: n.title || "PayPact", body: n.body || "" },
        data: {
          type: String(n.type || ""),
          groupId: String(n.groupId || ""),
          notificationId: notifId,
        },
      });
    } catch (err) {
      // A stale token is expected after uninstall / sign-out; drop it.
      if (
        err.code === "messaging/registration-token-not-registered" ||
        err.code === "messaging/invalid-registration-token"
      ) {
        await db.doc(`users/${userId}/private/push`).delete();
      } else {
        functions.logger.error("FCM send failed", { userId, error: err.message });
      }
    }
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Invite links
// ─────────────────────────────────────────────────────────────────────────────

function requireAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in first.");
  }
  return context.auth.uid;
}

async function findGroupByCode(rawCode) {
  const code = String(rawCode || "").trim().toUpperCase();
  if (!INVITE_CODE_RE.test(code)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid invite code.");
  }
  const q = await db.collection("groups").where("inviteCode", "==", code).limit(1).get();
  if (q.empty) {
    throw new functions.https.HttpsError("not-found", "This invite link is no longer valid.");
  }
  return q.docs[0];
}

/** Lets the join screen show what the user is about to join. */
exports.getInvitePreview = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const doc = await findGroupByCode(data && data.code);
  const g = doc.data();
  return {
    name: g.name || "",
    emoji: g.emoji || "✨",
    memberCount: (g.memberIds || []).length,
    alreadyMember: (g.memberIds || []).includes(uid),
  };
});

/** Adds the caller to the group that owns [code]. Idempotent. */
exports.joinGroupByCode = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const doc = await findGroupByCode(data && data.code);
  const group = doc.data();
  const groupId = doc.id;

  if ((group.memberIds || []).includes(uid)) {
    return { groupId, name: group.name || "", alreadyMember: true };
  }

  const userSnap = await db.doc(`users/${uid}`).get();
  const name =
    (userSnap.exists && userSnap.data().name) ||
    (context.auth.token && context.auth.token.name) ||
    "New member";

  await doc.ref.update({
    memberIds: admin.firestore.FieldValue.arrayUnion(uid),
    [`memberNames.${uid}`]: name,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Tell everyone already in the group (their pushes go out via the trigger).
  const batch = db.batch();
  for (const memberId of group.memberIds || []) {
    batch.set(db.collection(`users/${memberId}/notifications`).doc(), {
      type: "member_added",
      title: `${name} joined "${group.name}"`,
      body: "They used the invite link.",
      groupId,
      groupName: group.name || "",
      actorId: uid,
      actorName: name,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  return { groupId, name: group.name || "", alreadyMember: false };
});

// ─────────────────────────────────────────────────────────────────────────────
// Housekeeping
// ─────────────────────────────────────────────────────────────────────────────

/** The client deletes only the group document; clear its sub-collections. */
exports.onGroupDeleted = functions.firestore
  .document("groups/{groupId}")
  .onDelete(async (snap) => {
    await db.recursiveDelete(snap.ref);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Weekly digest — Sundays 8 PM IST
// ─────────────────────────────────────────────────────────────────────────────

exports.weeklyDigest = functions.pubsub
  .schedule("0 20 * * 0")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const weekAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 7 * 24 * 60 * 60 * 1000
    );

    // userId -> { groups:Set, expenseCount, net:{[currency]:minor} }
    const perUser = new Map();
    const bucket = (uid) => {
      if (!perUser.has(uid)) {
        perUser.set(uid, { groups: new Set(), expenseCount: 0, net: {} });
      }
      return perUser.get(uid);
    };

    const groups = await db.collection("groups").get();
    for (const g of groups.docs) {
      const data = g.data();
      const memberIds = data.memberIds || [];
      const currency = data.currency || "INR";
      const [expSnap, setSnap] = await Promise.all([
        g.ref.collection("expenses").get(),
        g.ref.collection("settlements").get(),
      ]);
      const expenses = expSnap.docs.map((d) => d.data());
      const net = computeNetBalances(
        expenses,
        setSnap.docs.map((d) => d.data()),
        memberIds
      );
      const recent = expSnap.docs.filter((d) => {
        const ts = d.data().createdAt;
        return ts && ts.toMillis() >= weekAgo.toMillis();
      }).length;

      for (const uid of memberIds) {
        const b = bucket(uid);
        b.groups.add(g.id);
        b.expenseCount += recent;
        b.net[currency] = (b.net[currency] || 0) + (net[uid] || 0);
      }
    }

    let sent = 0;
    for (const [uid, b] of perUser) {
      const userSnap = await db.doc(`users/${uid}`).get();
      const prefs = (userSnap.exists && userSnap.data().notifPrefs) || {};
      if (prefs.digest !== true) continue; // opt-in, matches the Settings default

      const digest = buildDigest({
        expenseCount: b.expenseCount,
        groupCount: b.groups.size,
        net: b.net,
      });
      if (!digest) continue;

      // Writing the inbox document triggers the push via onNotificationCreated.
      await db.collection(`users/${uid}/notifications`).add({
        type: "digest",
        title: digest.title,
        body: digest.body,
        groupId: null,
        groupName: null,
        actorId: "system",
        actorName: "PayPact",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      sent++;
    }
    functions.logger.info(`Weekly digest sent to ${sent} users`);
    return null;
  });
