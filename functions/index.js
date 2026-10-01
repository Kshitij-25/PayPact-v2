"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { classifyQuery, maskEmail } = require("./lib/userSearch");
const { api } = require("./lib/jobs");

admin.initializeApp();
const db = admin.firestore();
const jobs = api(admin);

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
    memberIds: FieldValue.arrayUnion(uid),
    [`memberNames.${uid}`]: name,
    updatedAt: FieldValue.serverTimestamp(),
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
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  return { groupId, name: group.name || "", alreadyMember: false };
});

// ─────────────────────────────────────────────────────────────────────────────
// Housekeeping
// ─────────────────────────────────────────────────────────────────────────────

/** The client deletes only the group document; clear its data and files. */
exports.onGroupDeleted = functions.firestore
  .document("groups/{groupId}")
  .onDelete(async (snap, context) => {
    await db.recursiveDelete(snap.ref);
    try {
      await admin.storage().bucket().deleteFiles({ prefix: `groups/${context.params.groupId}/` });
    } catch (err) {
      functions.logger.warn("Group file cleanup skipped", { error: err.message });
    }
    return null;
  });

/** Keeps `nameLower` (used for case-insensitive search) in step with `name`. */
exports.onUserWritten = functions.firestore
  .document("users/{userId}")
  .onWrite(async (change) => {
    if (!change.after.exists) return null;
    const { name, nameLower } = change.after.data();
    const want = typeof name === "string" ? name.trim().toLowerCase() : "";
    if (want && want !== nameLower) await change.after.ref.update({ nameLower: want });
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Group summaries (balances & totals kept on the group document)
// ─────────────────────────────────────────────────────────────────────────────

exports.onGroupCreated = functions.firestore
  .document("groups/{groupId}")
  .onCreate((snap) => jobs.recomputeGroup(snap.ref));

exports.onExpenseWritten = functions.firestore
  .document("groups/{groupId}/expenses/{expenseId}")
  .onWrite((change, context) =>
    jobs.onExpenseWritten(
      context.params.groupId,
      context.eventId,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null,
      Date.parse(context.timestamp)
    )
  );

exports.onSettlementCreated = functions.firestore
  .document("groups/{groupId}/settlements/{settlementId}")
  .onCreate((snap, context) =>
    jobs.onSettlementCreated(
      context.params.groupId,
      context.eventId,
      snap.data(),
      Date.parse(context.timestamp)
    )
  );

/** Backfill for groups that predate summaries; any member may request it. */
exports.recomputeGroupSummary = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const groupId = String((data && data.groupId) || "");
  const ref = db.doc(`groups/${groupId}`);
  const snap = await ref.get();
  if (!snap.exists || !(snap.data().memberIds || []).includes(uid)) {
    throw new functions.https.HttpsError("permission-denied", "Not a member of this group.");
  }
  await jobs.recomputeGroup(ref);
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────────────────────
// People search — replaces client-side queries so the users collection can't
// be enumerated, and so email addresses are never handed out in full.
// ─────────────────────────────────────────────────────────────────────────────

exports.searchUsers = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const { kind, q } = classifyQuery(data && data.query);
  if (kind === "none") return { users: [] };
  const exclude = new Set(((data && data.excludeIds) || []).map(String));
  exclude.add(uid);

  let docs;
  if (kind === "email") {
    docs = (await db.collection("users").where("email", "==", q).limit(5).get()).docs;
  } else {
    docs = (
      await db
        .collection("users")
        .orderBy("nameLower")
        .startAt(q)
        .endAt(q + "\uf8ff")
        .limit(10)
        .get()
    ).docs;
  }
  return {
    users: docs
      .filter((d) => !exclude.has(d.id))
      .map((d) => ({
        id: d.id,
        name: d.data().name || "",
        email: maskEmail(d.data().email || ""),
        photoUrl: d.data().photoUrl || null,
        // An exact email match is something the searcher already knew.
        exactEmail: kind === "email",
      })),
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// Account deletion
// ─────────────────────────────────────────────────────────────────────────────

const REAUTH_WINDOW_SECONDS = 5 * 60;

exports.deleteAccount = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  // Deleting an account is destructive: require a sign-in from the last few
  // minutes (the app re-authenticates the user right before calling this).
  const authTime = (context.auth.token && context.auth.token.auth_time) || 0;
  if (Date.now() / 1000 - authTime > REAUTH_WINDOW_SECONDS) {
    throw new functions.https.HttpsError("unauthenticated", "recent-login-required");
  }
  const result = await jobs.deleteAccount(uid);
  if (!result.ok) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "unsettled-balances",
      { blockers: result.blockers }
    );
  }
  return result;
});

// ─────────────────────────────────────────────────────────────────────────────
// Scheduled jobs
// ─────────────────────────────────────────────────────────────────────────────

exports.weeklyDigest = functions.pubsub
  .schedule("0 20 * * 0")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const sent = await jobs.runDigest();
    functions.logger.info(`Weekly digest sent to ${sent} users`);
    return null;
  });

exports.runRecurringExpenses = functions.pubsub
  .schedule("0 3 * * *")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const created = await jobs.runRecurring();
    const cleaned = await jobs.cleanupEvents();
    functions.logger.info(`Recurring: created ${created} expenses; cleaned ${cleaned} events`);
    return null;
  });
