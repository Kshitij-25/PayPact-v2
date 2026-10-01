"use strict";

const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { buildSummary, expenseDelta, settlementDelta, SUMMARY_VERSION } = require("./summary");
const { buildDigest, computeNetBalances } = require("./balances");
const { dueOccurrences } = require("./recurring");
const { planAccountDeletion } = require("./accountDeletion");
const { shouldDeliver } = require("./prefs");

/** Every job takes `admin` so tests can hand in an emulator-backed instance. */
function api(admin) {
  const db = admin.firestore();

  // ── Summaries ────────────────────────────────────────────────────────────

  /**
   * Rebuilds a group's summary from every expense and settlement, from one
   * consistent snapshot, and records that snapshot's time as `summaryAsOf`.
   * Trigger events stamped at or before that time are already counted in the
   * rebuild and are skipped by [applyDelta] — that is what stops an expense
   * from being counted twice when it arrives while a rebuild is running.
   */
  async function recomputeGroup(groupRef) {
    return db.runTransaction(async (txn) => {
      const [groupSnap, exp, set] = await Promise.all([
        txn.get(groupRef),
        txn.get(groupRef.collection("expenses")),
        txn.get(groupRef.collection("settlements")),
      ]);
      if (!groupSnap.exists) return null;
      const summary = buildSummary({
        expenses: exp.docs.map((d) => d.data()),
        settlements: set.docs.map((d) => d.data()),
        memberIds: groupSnap.data().memberIds || [],
      });

      let lastActivity = null;
      for (const d of [...exp.docs, ...set.docs]) {
        const t = d.data().createdAt;
        if (t && (!lastActivity || t.toMillis() > lastActivity.toMillis())) lastActivity = t;
      }
      txn.update(groupRef, {
        ...summary,
        summaryAsOf: exp.readTime,
        ...(lastActivity ? { lastActivityAt: lastActivity } : {}),
      });
      return summary;
    });
  }

  /**
   * Applies a delta exactly once per trigger event. Triggers are at-least-once,
   * so the event id is recorded in the same transaction as the increments.
   * Groups without a (current) summary are rebuilt from scratch instead, and
   * events the last rebuild already covers are skipped.
   * @param {number} [eventTimeMs] commit time of the write that caused the event
   */
  async function applyDelta(groupId, eventId, delta, { title, eventTimeMs } = {}) {
    const groupRef = db.doc(`groups/${groupId}`);
    const eventRef = groupRef.collection("_events").doc(eventId);

    const needsRebuild = await db.runTransaction(async (txn) => {
      const [group, event] = await Promise.all([txn.get(groupRef), txn.get(eventRef)]);
      if (!group.exists || event.exists) return false; // gone, or already applied
      txn.set(eventRef, {
        at: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + 2 * 24 * 3600 * 1000),
      });
      const g = group.data();
      if (g.summaryVersion !== SUMMARY_VERSION || !g.summaryAsOf) return true;
      // Already part of the last rebuild's snapshot.
      if (eventTimeMs !== undefined && eventTimeMs <= g.summaryAsOf.toMillis()) {
        return false;
      }

      const update = {
        totalSpentMinor: FieldValue.increment(delta.totalSpentMinor),
        expenseCount: FieldValue.increment(delta.expenseCount),
        lastActivityAt: FieldValue.serverTimestamp(),
      };
      if (title !== undefined) update.lastExpenseTitle = title;
      for (const [uid, minor] of Object.entries(delta.balances)) {
        update[`balances.${uid}`] = FieldValue.increment(minor);
      }
      txn.update(groupRef, update);
      return false;
    });
    if (needsRebuild) await recomputeGroup(groupRef);
  }

  const onExpenseWritten = (groupId, eventId, before, after, eventTimeMs) =>
    applyDelta(groupId, eventId, expenseDelta(before, after), {
      title: after ? after.title || "" : undefined,
      eventTimeMs,
    });

  const onSettlementCreated = (groupId, eventId, settlement, eventTimeMs) =>
    applyDelta(groupId, eventId, settlementDelta(settlement), { eventTimeMs });

  async function cleanupEvents() {
    const old = await db
      .collectionGroup("_events")
      .where("expiresAt", "<=", Timestamp.now())
      .limit(400)
      .get();
    const batch = db.batch();
    old.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    return old.size;
  }

  // ── Weekly digest ────────────────────────────────────────────────────────

  async function runDigest(now = new Date()) {
    const weekAgo = Timestamp.fromMillis(now.getTime() - 7 * 24 * 3600 * 1000);
    const perUser = new Map();
    const bucket = (uid) => {
      if (!perUser.has(uid)) perUser.set(uid, { groups: new Set(), expenseCount: 0, net: {} });
      return perUser.get(uid);
    };

    const groups = await db.collection("groups").get();
    for (const g of groups.docs) {
      const data = g.data();
      const memberIds = data.memberIds || [];
      const currency = data.currency || "INR";

      // Prefer the maintained summary; fall back to scanning for old groups.
      let net = data.summaryVersion === SUMMARY_VERSION ? data.balances || {} : null;
      if (!net) {
        const [e, s] = await Promise.all([
          g.ref.collection("expenses").get(),
          g.ref.collection("settlements").get(),
        ]);
        net = computeNetBalances(
          e.docs.map((d) => d.data()),
          s.docs.map((d) => d.data()),
          memberIds
        );
      }
      const recent = (
        await g.ref.collection("expenses").where("createdAt", ">=", weekAgo).count().get()
      ).data().count;

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
      const user = userSnap.exists ? userSnap.data() : {};
      if (!shouldDeliver("digest", null, user)) continue;
      const digest = buildDigest({
        expenseCount: b.expenseCount,
        groupCount: b.groups.size,
        net: b.net,
      });
      if (!digest) continue;
      await db.collection(`users/${uid}/notifications`).add({
        type: "digest",
        title: digest.title,
        body: digest.body,
        groupId: null,
        groupName: null,
        actorId: "system",
        actorName: "PayPact",
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
      sent++;
    }
    return sent;
  }

  // ── Recurring expenses ───────────────────────────────────────────────────

  async function runRecurring(now = new Date()) {
    const due = await db
      .collectionGroup("recurring")
      .where("active", "==", true)
      .where("nextRunAt", "<=", Timestamp.fromDate(now))
      .get();

    let created = 0;
    for (const doc of due.docs) {
      const t = doc.data();
      const groupRef = doc.ref.parent.parent;
      const group = await groupRef.get();
      const members = group.exists ? group.data().memberIds || [] : [];

      // The template's owner or payer left, or the group is gone: stop it.
      if (!group.exists || !members.includes(t.createdById) || !members.includes(t.paidById)) {
        await doc.ref.update({ active: false });
        continue;
      }

      const { due: dates, next } = dueOccurrences(t.nextRunAt.toDate(), t.interval, now);
      for (const date of dates) {
        const expenseRef = groupRef.collection("expenses").doc();
        await expenseRef.set({
          title: t.title,
          amount: t.amount,
          originalAmount: t.originalAmount ?? t.amount,
          originalCurrency: t.originalCurrency || group.data().currency || "INR",
          exchangeRate: t.exchangeRate ?? 1,
          category: t.category || "other",
          paidById: t.paidById,
          paidByName: t.paidByName || "",
          splits: t.splits || [],
          note: t.note || null,
          date: Timestamp.fromDate(date),
          recurringId: doc.id,
          createdAt: FieldValue.serverTimestamp(),
          createdById: t.createdById,
        });
        created++;

        for (const memberId of members) {
          if (memberId === t.createdById) continue;
          const userSnap = await db.doc(`users/${memberId}`).get();
          if (!shouldDeliver("expense_added", groupRef.id, userSnap.exists ? userSnap.data() : {})) continue;
          await db.collection(`users/${memberId}/notifications`).add({
            type: "expense_added",
            title: `Recurring expense added`,
            body: `"${t.title}" was added to ${group.data().name}.`,
            groupId: groupRef.id,
            groupName: group.data().name || "",
            actorId: t.createdById,
            actorName: t.createdByName || "",
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
      }
      await doc.ref.update({ nextRunAt: Timestamp.fromDate(next), lastRunAt: Timestamp.fromDate(now) });
    }
    return created;
  }

  // ── Account deletion ─────────────────────────────────────────────────────

  async function deleteAccount(uid) {
    const groupsSnap = await db.collection("groups").where("memberIds", "array-contains", uid).get();

    const groups = [];
    for (const g of groupsSnap.docs) {
      const d = g.data();
      // Always rebuild: a stale summary must never let someone leave with debt.
      const summary = await recomputeGroup(g.ref);
      groups.push({
        id: g.id,
        name: d.name || "",
        currency: d.currency || "INR",
        memberIds: d.memberIds || [],
        adminIds: d.adminIds || [d.createdBy],
        createdBy: d.createdBy,
        netMinor: (summary && summary.balances[uid]) || 0,
      });
    }

    const plan = planAccountDeletion(uid, groups);
    if (plan.blockers.length) return { ok: false, blockers: plan.blockers };

    const userSnap = await db.doc(`users/${uid}`).get();
    const name = (userSnap.exists && userSnap.data().name) || "A member";

    for (const action of plan.actions) {
      const ref = db.doc(`groups/${action.groupId}`);
      if (action.type === "delete_group") {
        await ref.delete(); // onGroupDeleted removes its sub-collections and files
        continue;
      }
      const snap = await ref.get();
      const d = snap.data();
      const admins = (d.adminIds || [d.createdBy]).filter((a) => a !== uid);
      if (action.promote && !admins.includes(action.promote)) admins.push(action.promote);
      await ref.update({
        memberIds: FieldValue.arrayRemove(uid),
        [`memberNames.${uid}`]: FieldValue.delete(),
        adminIds: admins,
        updatedAt: FieldValue.serverTimestamp(),
      });
      const batch = db.batch();
      for (const m of d.memberIds.filter((x) => x !== uid)) {
        batch.set(db.collection(`users/${m}/notifications`).doc(), {
          type: "member_removed",
          title: `${name} left "${d.name}"`,
          body: "Their account was deleted.",
          groupId: action.groupId,
          groupName: d.name || "",
          actorId: uid,
          actorName: name,
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    await db.recursiveDelete(db.doc(`users/${uid}`));
    try {
      await admin.storage().bucket().file(`avatars/${uid}.jpg`).delete({ ignoreNotFound: true });
    } catch (_) {
      // storage may be unavailable (emulator); the profile is gone either way
    }
    await admin.auth().deleteUser(uid);
    return { ok: true, left: plan.actions.length };
  }

  return {
    recomputeGroup,
    applyDelta,
    onExpenseWritten,
    onSettlementCreated,
    cleanupEvents,
    runDigest,
    runRecurring,
    deleteAccount,
  };
}

module.exports = { api };
