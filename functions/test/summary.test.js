"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { expenseDelta, settlementDelta, buildSummary, expenseContribution } = require("../lib/summary");
const { computeNetBalances } = require("../lib/balances");

const dinner = {
  amount: 300, paidById: "a", title: "Dinner",
  splits: [{ userId: "a", amount: 100 }, { userId: "b", amount: 100 }, { userId: "c", amount: 100 }],
};

test("create: payer gains, splitters owe, totals move", () => {
  assert.deepEqual(expenseDelta(null, dinner), {
    balances: { a: 20000, b: -10000, c: -10000 },
    totalSpentMinor: 30000,
    expenseCount: 1,
  });
});

test("delete exactly reverses create", () => {
  const up = expenseDelta(null, dinner);
  const down = expenseDelta(dinner, null);
  for (const k of Object.keys(up.balances)) assert.equal(up.balances[k] + down.balances[k], 0);
  assert.equal(up.totalSpentMinor + down.totalSpentMinor, 0);
  assert.equal(up.expenseCount + down.expenseCount, 0);
});

test("edit applies only the difference (payer change)", () => {
  const edited = { ...dinner, paidById: "b" };
  const d = expenseDelta(dinner, edited);
  assert.deepEqual(d.balances, { a: -30000, b: 30000 });
  assert.equal(d.expenseCount, 0);
  assert.equal(d.totalSpentMinor, 0);
});

test("edit that changes nothing financial yields an empty delta", () => {
  const d = expenseDelta(dinner, { ...dinner, title: "Dinner out", note: "x" });
  assert.deepEqual(d.balances, {});
});

test("settlement moves money from payer to payee", () => {
  assert.deepEqual(settlementDelta({ fromUserId: "b", toUserId: "a", amountPaise: 5000 }).balances,
    { b: 5000, a: -5000 });
  assert.deepEqual(settlementDelta({ fromUserId: "b", toUserId: "a", amount: 12.5 }).balances,
    { b: 1250, a: -1250 });
});

test("contributions are zero-sum", () => {
  const sum = Object.values(expenseContribution(dinner)).reduce((a, b) => a + b, 0);
  assert.equal(sum, 0);
});

test("incremental deltas always agree with a full rebuild", () => {
  const e2 = { amount: 90, paidById: "c", title: "Taxi", splits: [{ userId: "a", amount: 45 }, { userId: "c", amount: 45 }] };
  const s1 = { fromUserId: "b", toUserId: "a", amountPaise: 4000 };

  const acc = {};
  const apply = (d) => { for (const [k, v] of Object.entries(d.balances)) acc[k] = (acc[k] || 0) + v; };
  apply(expenseDelta(null, dinner));
  apply(expenseDelta(null, e2));
  apply(settlementDelta(s1));
  apply(expenseDelta(e2, { ...e2, amount: 100, splits: [{ userId: "a", amount: 50 }, { userId: "c", amount: 50 }] }));

  const e2b = { ...e2, amount: 100, splits: [{ userId: "a", amount: 50 }, { userId: "c", amount: 50 }] };
  const full = computeNetBalances([dinner, e2b], [s1], ["a", "b", "c"]);
  for (const id of ["a", "b", "c"]) assert.equal(acc[id] || 0, full[id], id);
});

test("buildSummary rebuilds totals, count and balances", () => {
  const s = buildSummary({ expenses: [dinner], settlements: [], memberIds: ["a", "b", "c"] });
  assert.equal(s.totalSpentMinor, 30000);
  assert.equal(s.expenseCount, 1);
  assert.equal(s.summaryVersion, 1);
  assert.deepEqual(s.balances, { a: 20000, b: -10000, c: -10000 });
  assert.equal(s.lastExpenseTitle, "Dinner");
});

test("buildSummary keeps balances of people who left the group", () => {
  const s = buildSummary({ expenses: [dinner], settlements: [], memberIds: ["a"] });
  assert.equal(s.balances.b, -10000);
});
