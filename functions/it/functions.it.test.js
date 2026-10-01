"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { admin, db, signUp, call, eventually, makeGroup, uniq } = require("./helpers");
const { api } = require("../lib/jobs");

const jobs = api(admin);
const { FieldValue: FV, Timestamp: TS } = require("firebase-admin/firestore");

const expense = (payer, total, among, extra = {}) => ({
  title: "Dinner", amount: total, originalAmount: total, originalCurrency: "INR", exchangeRate: 1,
  category: "food", paidById: payer.uid, paidByName: payer.name,
  splits: among.map((u) => ({ userId: u.uid, userName: u.name, amount: total / among.length })),
  createdAt: FV.serverTimestamp(), createdById: payer.uid, ...extra,
});

const balances = async (ref) => (await ref.get()).data().balances || {};

// ── summaries ──────────────────────────────────────────────────────────────
test("summary: expense create / edit / delete and settlements keep balances exact", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const ref = await makeGroup(`s${uniq()}`, { admin: a.uid, members: [a, b] });

  // onGroupCreated gives the group a summary
  await eventually(async () => (await ref.get()).data().summaryVersion === 1, { what: "initial summary" });

  const e1 = await ref.collection("expenses").add(expense(a, 200, [a, b]));
  await eventually(async () => (await balances(ref))[b.uid] === -10000, { what: "create applied" });
  let g = (await ref.get()).data();
  assert.equal(g.balances[a.uid], 10000);
  assert.equal(g.totalSpentMinor, 20000);
  assert.equal(g.expenseCount, 1);
  assert.equal(g.lastExpenseTitle, "Dinner");

  await e1.update({ amount: 300, splits: expense(a, 300, [a, b]).splits });
  await eventually(async () => (await balances(ref))[b.uid] === -15000, { what: "edit applied" });
  assert.equal((await ref.get()).data().totalSpentMinor, 30000);
  assert.equal((await ref.get()).data().expenseCount, 1);

  await ref.collection("settlements").doc("s1").set({
    fromUserId: b.uid, toUserId: a.uid, amountPaise: 5000, amount: 50, createdById: b.uid,
    createdAt: FV.serverTimestamp(),
  });
  await eventually(async () => (await balances(ref))[b.uid] === -10000, { what: "settlement applied" });

  await e1.delete();
  await eventually(async () => (await ref.get()).data().expenseCount === 0, { what: "delete applied" });
  g = (await ref.get()).data();
  assert.equal(g.totalSpentMinor, 0);
  // only the settlement remains: b paid a 50
  assert.equal(g.balances[b.uid], 5000);
  assert.equal(g.balances[a.uid], -5000);
});

test("summary: expenses written right after the group is created are counted exactly once", async () => {
  // The race: the group-created rebuild and the expense triggers run together.
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const ref = await makeGroup(`race${uniq()}`, { admin: a.uid, members: [a, b] });
  await Promise.all([
    ref.collection("expenses").add(expense(a, 2400, [a, b])),
    ref.collection("expenses").add(expense(b, 900, [a, b], { title: "Scooter" })),
    ref.collection("expenses").add(expense(a, 6000, [a, b], { title: "Villa" })),
  ]);
  await eventually(async () => {
    const g = (await ref.get()).data();
    return g.summaryVersion === 1 && g.expenseCount === 3;
  }, { what: "three expenses counted" });
  // give any late/duplicate trigger time to (wrongly) double-apply
  await new Promise((r) => setTimeout(r, 4000));
  const g = (await ref.get()).data();
  assert.equal(g.expenseCount, 3);
  assert.equal(g.totalSpentMinor, 930000);
  assert.equal(g.balances[a.uid], 375000); // paid 8400, owes 4650
  assert.equal(g.balances[b.uid], -375000);
});

test("summary: a group that predates summaries is rebuilt on its first change", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const ref = await makeGroup(`old${uniq()}`, { admin: a.uid, members: [a, b] });
  await eventually(async () => (await ref.get()).data().summaryVersion === 1);
  await ref.update({ summaryVersion: FV.delete(), balances: FV.delete(), totalSpentMinor: FV.delete() });

  await ref.collection("expenses").add(expense(a, 90, [a, b]));
  await eventually(async () => (await ref.get()).data().summaryVersion === 1, { what: "rebuild" });
  const g = (await ref.get()).data();
  assert.equal(g.balances[b.uid], -4500);
  assert.equal(g.totalSpentMinor, 9000);
});

test("summary: a duplicate trigger delivery is applied once", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const ref = await makeGroup(`d${uniq()}`, { admin: a.uid, members: [a, b] });
  await eventually(async () => (await ref.get()).data().summaryVersion === 1);

  const e = expense(a, 100, [a, b]);
  await jobs.onExpenseWritten(ref.id, "evt-1", null, e);
  await jobs.onExpenseWritten(ref.id, "evt-1", null, e); // redelivery
  assert.equal((await ref.get()).data().balances[b.uid], -5000);
  assert.equal((await ref.get()).data().expenseCount, 1);
});

test("recomputeGroupSummary: members only", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const c = await signUp(`c${uniq()}@t.io`, "Cy");
  const ref = await makeGroup(`r${uniq()}`, { admin: a.uid, members: [a] });
  assert.equal((await call("recomputeGroupSummary", { groupId: ref.id }, a.token)).result.ok, true);
  const denied = await call("recomputeGroupSummary", { groupId: ref.id }, c.token);
  assert.equal(denied.error.status, "PERMISSION_DENIED");
  const anon = await call("recomputeGroupSummary", { groupId: ref.id });
  assert.equal(anon.error.status, "UNAUTHENTICATED");
});

// ── invites ────────────────────────────────────────────────────────────────
test("invites: preview then join adds the member and tells the others", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const code = ("T" + uniq() + "XYZ").toUpperCase().slice(0, 8);
  const ref = await makeGroup(`i${uniq()}`, { admin: a.uid, members: [a], extra: { inviteCode: code } });

  const preview = await call("getInvitePreview", { code }, b.token);
  assert.equal(preview.result.memberCount, 1);
  assert.equal(preview.result.alreadyMember, false);

  const join = await call("joinGroupByCode", { code: code.toLowerCase() }, b.token);
  assert.equal(join.result.groupId, ref.id);
  const g = (await ref.get()).data();
  assert.deepEqual(g.memberIds.sort(), [a.uid, b.uid].sort());
  assert.equal(g.memberNames[b.uid], "Ben");

  const notes = await db.collection(`users/${a.uid}/notifications`).where("type", "==", "member_added").get();
  assert.equal(notes.size, 1);

  // idempotent
  assert.equal((await call("joinGroupByCode", { code }, b.token)).result.alreadyMember, true);
  // bad / unknown codes
  assert.equal((await call("joinGroupByCode", { code: "NOPE" }, b.token)).error.status, "INVALID_ARGUMENT");
  assert.equal((await call("joinGroupByCode", { code: "ZZZZZZZZ" }, b.token)).error.status, "NOT_FOUND");
});

// ── search ─────────────────────────────────────────────────────────────────
test("searchUsers: masks emails, is case-insensitive, excludes people, needs sign-in", async () => {
  const tag = uniq();
  const a = await signUp(`searcher${tag}@t.io`, "Searcher");
  const b = await signUp(`priya${tag}@t.io`, `Priya ${tag}`);
  const c = await signUp(`priyanka${tag}@t.io`, `Priyanka ${tag}`);
  // the nameLower trigger needs a moment
  await eventually(async () => (await db.doc(`users/${b.uid}`).get()).data().nameLower, { what: "nameLower" });
  await eventually(async () => (await db.doc(`users/${c.uid}`).get()).data().nameLower, { what: "nameLower" });

  const byName = await call("searchUsers", { query: `PRIYA ${tag}` }, a.token);
  assert.ok(byName.result.users.some((u) => u.id === b.uid));
  const hit = byName.result.users.find((u) => u.id === b.uid);
  assert.ok(!hit.email.includes(`priya${tag}`), "email must be masked");
  assert.match(hit.email, /@t\.io$/);

  const prefix = await call("searchUsers", { query: "priy" }, a.token);
  assert.ok(prefix.result.users.length >= 2);

  const byEmail = await call("searchUsers", { query: `PRIYA${tag}@T.io` }, a.token);
  assert.deepEqual(byEmail.result.users.map((u) => u.id), [b.uid]);
  assert.equal(byEmail.result.users[0].exactEmail, true);

  const excluded = await call("searchUsers", { query: `priya ${tag}`, excludeIds: [b.uid] }, a.token);
  assert.ok(!excluded.result.users.some((u) => u.id === b.uid));

  assert.deepEqual((await call("searchUsers", { query: "p" }, a.token)).result.users, []);
  assert.equal((await call("searchUsers", { query: "priya" })).error.status, "UNAUTHENTICATED");
});

// ── account deletion ───────────────────────────────────────────────────────
test("deleteAccount: refuses while money is owed, listing the groups", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const ref = await makeGroup(`x${uniq()}`, { admin: a.uid, members: [a, b] });
  await eventually(async () => (await ref.get()).data().summaryVersion === 1);
  await ref.collection("expenses").add(expense(a, 100, [a, b]));
  await eventually(async () => (await ref.get()).data().expenseCount === 1);

  const res = await call("deleteAccount", {}, b.token);
  assert.equal(res.error.status, "FAILED_PRECONDITION");
  assert.equal(res.error.details.blockers[0].netMinor, -5000);
  // nothing was touched
  assert.ok((await ref.get()).data().memberIds.includes(b.uid));
  assert.ok((await db.doc(`users/${b.uid}`).get()).exists);
});

test("deleteAccount: a settled member leaves; the sole admin hands the group on", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const solo = await makeGroup(`solo${uniq()}`, { admin: a.uid, members: [a] });
  const shared = await makeGroup(`sh${uniq()}`, { admin: a.uid, members: [a, b] });
  await db.collection(`users/${a.uid}/notifications`).add({ type: "x", title: "t" });

  const res = await call("deleteAccount", {}, a.token);
  assert.equal(res.result.ok, true);

  assert.equal((await solo.get()).exists, false, "single-member group is deleted");
  const g = (await shared.get()).data();
  assert.deepEqual(g.memberIds, [b.uid]);
  assert.deepEqual(g.adminIds, [b.uid], "admin role passed to the remaining member");
  assert.equal(g.memberNames[a.uid], undefined);
  assert.equal((await db.doc(`users/${a.uid}`).get()).exists, false);
  assert.equal((await db.collection(`users/${a.uid}/notifications`).get()).size, 0);
  await assert.rejects(admin.auth().getUser(a.uid), /no user record/i);

  const told = await db.collection(`users/${b.uid}/notifications`).where("type", "==", "member_removed").get();
  assert.equal(told.size, 1);
});

test("deleteAccount: needs a recent sign-in", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  // forge a token whose auth_time is an hour old (the emulator accepts unsigned JWTs)
  const [h, p] = a.token.split(".");
  const payload = JSON.parse(Buffer.from(p, "base64url").toString());
  payload.auth_time = Math.floor(Date.now() / 1000) - 3600;
  const stale = `${h}.${Buffer.from(JSON.stringify(payload)).toString("base64url")}.`;
  const res = await call("deleteAccount", {}, stale);
  assert.equal(res.error.message, "recent-login-required");
  assert.ok((await db.doc(`users/${a.uid}`).get()).exists);
});

// ── housekeeping ───────────────────────────────────────────────────────────
test("deleting a group removes its expenses and settlements", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const ref = await makeGroup(`gd${uniq()}`, { admin: a.uid, members: [a] });
  await ref.collection("expenses").add(expense(a, 10, [a]));
  await ref.collection("settlements").doc("s").set({ amount: 1 });
  await ref.delete();
  await eventually(async () => (await ref.collection("expenses").get()).empty, { what: "cleanup" });
  assert.ok((await ref.collection("settlements").get()).empty);
});

test("users get a lower-cased name for search", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "MiXeD Case");
  await eventually(async () => (await db.doc(`users/${a.uid}`).get()).data().nameLower === "mixed case");
  await db.doc(`users/${a.uid}`).update({ name: "Renamed Person" });
  await eventually(async () => (await db.doc(`users/${a.uid}`).get()).data().nameLower === "renamed person");
});

// ── recurring ──────────────────────────────────────────────────────────────
test("recurring: due templates become expenses and move forward; stale ones stop", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const ref = await makeGroup(`rc${uniq()}`, { admin: a.uid, members: [a, b] });
  const tpl = ref.collection("recurring").doc("rent");
  const tenDaysAgo = new Date(Date.now() - 10 * 24 * 3600 * 1000);
  await tpl.set({
    title: "Rent", amount: 100, originalAmount: 100, originalCurrency: "INR", exchangeRate: 1,
    category: "stay", paidById: a.uid, paidByName: "Asha",
    splits: [{ userId: a.uid, userName: "Asha", amount: 50 }, { userId: b.uid, userName: "Ben", amount: 50 }],
    interval: "weekly", nextRunAt: TS.fromDate(tenDaysAgo), active: true,
    createdById: a.uid, createdByName: "Asha",
  });

  const created = await jobs.runRecurring(new Date());
  assert.equal(created, 2); // 10 days ago and 3 days ago
  const exp = await ref.collection("expenses").where("recurringId", "==", "rent").get();
  assert.equal(exp.size, 2);
  assert.equal(exp.docs[0].data().title, "Rent");
  const t = (await tpl.get()).data();
  assert.ok(t.nextRunAt.toMillis() > Date.now());
  assert.equal(t.active, true);
  // the other member heard about it
  assert.ok((await db.collection(`users/${b.uid}/notifications`).get()).size >= 2);

  // running again immediately creates nothing
  assert.equal(await jobs.runRecurring(new Date()), 0);

  // if the template's owner leaves, it stops instead of creating expenses
  await tpl.update({ nextRunAt: TS.fromDate(tenDaysAgo) });
  await ref.update({ memberIds: [b.uid] });
  assert.equal(await jobs.runRecurring(new Date()), 0);
  assert.equal((await tpl.get()).data().active, false);
});

// ── digest ─────────────────────────────────────────────────────────────────
test("digest: only opted-in people hear about their week", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const b = await signUp(`b${uniq()}@t.io`, "Ben");
  const ref = await makeGroup(`dg${uniq()}`, { admin: a.uid, members: [a, b] });
  await eventually(async () => (await ref.get()).data().summaryVersion === 1);
  await ref.collection("expenses").add(expense(a, 200, [a, b]));
  await eventually(async () => (await ref.get()).data().expenseCount === 1);
  await db.doc(`users/${a.uid}`).update({ notifPrefs: { digest: true } });

  await jobs.runDigest(new Date());

  const toA = await db.collection(`users/${a.uid}/notifications`).where("type", "==", "digest").get();
  assert.equal(toA.size, 1);
  assert.match(toA.docs[0].data().body, /1 new expense/);
  assert.match(toA.docs[0].data().body, /you're owed ₹100/);
  const toB = await db.collection(`users/${b.uid}/notifications`).where("type", "==", "digest").get();
  assert.equal(toB.size, 0, "digest is opt-in");
});

test("event ledger entries expire", async () => {
  const a = await signUp(`a${uniq()}@t.io`, "Asha");
  const ref = await makeGroup(`ev${uniq()}`, { admin: a.uid, members: [a] });
  await ref.collection("_events").doc("old").set({ expiresAt: TS.fromMillis(Date.now() - 1000) });
  await ref.collection("_events").doc("new").set({ expiresAt: TS.fromMillis(Date.now() + 3600000) });
  await jobs.cleanupEvents();
  assert.equal((await ref.collection("_events").doc("old").get()).exists, false);
  assert.equal((await ref.collection("_events").doc("new").get()).exists, true);
});
