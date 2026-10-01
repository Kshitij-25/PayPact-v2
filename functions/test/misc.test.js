"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { nextOccurrence, dueOccurrences, MAX_CATCH_UP } = require("../lib/recurring");
const { planAccountDeletion } = require("../lib/accountDeletion");
const { shouldDeliver } = require("../lib/prefs");
const { maskEmail, classifyQuery } = require("../lib/userSearch");

const d = (s) => new Date(s + "T00:00:00Z");
const iso = (x) => x.toISOString().slice(0, 10);

test("weekly and monthly recurrence", () => {
  assert.equal(iso(nextOccurrence(d("2026-01-01"), "weekly")), "2026-01-08");
  assert.equal(iso(nextOccurrence(d("2026-01-15"), "monthly")), "2026-02-15");
  assert.equal(iso(nextOccurrence(d("2026-12-20"), "monthly")), "2027-01-20");
});

test("monthly recurrence clamps to the end of short months", () => {
  assert.equal(iso(nextOccurrence(d("2026-01-31"), "monthly")), "2026-02-28");
  assert.equal(iso(nextOccurrence(d("2028-01-31"), "monthly")), "2028-02-29");
});

test("due occurrences catch up on missed runs and report the next one", () => {
  const { due, next } = dueOccurrences(d("2026-01-01"), "weekly", d("2026-01-20"));
  assert.deepEqual(due.map(iso), ["2026-01-01", "2026-01-08", "2026-01-15"]);
  assert.equal(iso(next), "2026-01-22");
});

test("nothing is due before the first run date", () => {
  const { due, next } = dueOccurrences(d("2026-02-01"), "monthly", d("2026-01-20"));
  assert.deepEqual(due, []);
  assert.equal(iso(next), "2026-02-01");
});

test("a huge backlog is capped instead of flooding the group", () => {
  const { due, next } = dueOccurrences(d("2020-01-01"), "weekly", d("2026-01-20"));
  assert.equal(due.length, MAX_CATCH_UP);
  assert.ok(next.getTime() > d("2026-01-20").getTime());
});

const g = (over) => ({
  id: "g", name: "Trip", currency: "INR", memberIds: ["me", "x"], adminIds: ["me"],
  createdBy: "me", netMinor: 0, ...over,
});

test("deletion: a settled member simply leaves", () => {
  const p = planAccountDeletion("me", [g({ adminIds: ["me", "x"] })]);
  assert.deepEqual(p.blockers, []);
  assert.deepEqual(p.actions, [{ type: "leave", groupId: "g", name: "Trip" }]);
});

test("deletion: sole admin hands the group to the next member", () => {
  const p = planAccountDeletion("me", [g({ memberIds: ["me", "x", "y"] })]);
  assert.equal(p.actions[0].promote, "x");
});

test("deletion: a group of one is deleted, even with a balance", () => {
  const p = planAccountDeletion("me", [g({ memberIds: ["me"], netMinor: 500 })]);
  assert.deepEqual(p.actions, [{ type: "delete_group", groupId: "g", name: "Trip" }]);
});

test("deletion: any unsettled balance blocks, listing every group", () => {
  const p = planAccountDeletion("me", [
    g({ id: "a", netMinor: -2500 }),
    g({ id: "b", netMinor: 0 }),
    g({ id: "c", netMinor: 100 }),
  ]);
  assert.deepEqual(p.blockers.map((b) => b.groupId), ["a", "c"]);
  assert.equal(p.blockers[0].netMinor, -2500);
});

test("deletion: legacy group without adminIds treats the creator as admin", () => {
  const p = planAccountDeletion("me", [g({ adminIds: undefined })]);
  assert.equal(p.actions[0].promote, "x");
});

test("server prefs mirror the client rule", () => {
  assert.equal(shouldDeliver("expense_added", "g", {}), true);
  assert.equal(shouldDeliver("digest", null, {}), false);
  assert.equal(shouldDeliver("expense_added", "g", { notifPrefs: { expenses: false } }), false);
  assert.equal(shouldDeliver("expense_comment", "g", { notifPrefs: { expenses: false } }), false);
  assert.equal(shouldDeliver("nudge", "g1", { mutedGroups: ["g1"] }), false);
  assert.equal(shouldDeliver("member_removed", "g1", { mutedGroups: ["g1"] }), true);
});

test("search: masking and query classification", () => {
  assert.equal(maskEmail("kshitij@gmail.com"), "k••••@gmail.com");
  assert.equal(maskEmail("ab@x.io"), "a•@x.io");
  assert.deepEqual(classifyQuery(" Asha "), { kind: "name", q: "asha" });
  assert.equal(classifyQuery("A@B.com").kind, "email");
  assert.equal(classifyQuery("a").kind, "none");
});
