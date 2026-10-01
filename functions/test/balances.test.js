"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { computeNetBalances, buildDigest, formatMoney } = require("../lib/balances");

test("payer is owed, split members owe", () => {
  const net = computeNetBalances(
    [{ amount: 300, paidById: "a", splits: [
      { userId: "a", amount: 100 }, { userId: "b", amount: 100 }, { userId: "c", amount: 100 }] }],
    [],
    ["a", "b", "c"]
  );
  assert.deepEqual(net, { a: 20000, b: -10000, c: -10000 });
});

test("settlement moves balance from payer toward zero", () => {
  const net = computeNetBalances(
    [{ amount: 200, paidById: "a", splits: [
      { userId: "a", amount: 100 }, { userId: "b", amount: 100 }] }],
    [{ fromUserId: "b", toUserId: "a", amountPaise: 10000 }],
    ["a", "b"]
  );
  assert.deepEqual(net, { a: 0, b: 0 });
});

test("legacy settlement with only `amount` still reconciles; decimals stay exact", () => {
  const net = computeNetBalances(
    [{ amount: 10.25, paidById: "a", splits: [
      { userId: "a", amount: 5.12 }, { userId: "b", amount: 5.13 }] }],
    [{ fromUserId: "b", toUserId: "a", amount: 5.13 }],
    ["a", "b"]
  );
  assert.deepEqual(net, { a: 0, b: 0 });
});

test("ignores people who are no longer members", () => {
  const net = computeNetBalances(
    [{ amount: 100, paidById: "gone", splits: [{ userId: "a", amount: 100 }] }],
    [],
    ["a"]
  );
  assert.deepEqual(net, { a: -10000 });
});

test("digest wording", () => {
  assert.equal(buildDigest({ expenseCount: 0, groupCount: 2, net: { INR: 50 } }), null);
  assert.deepEqual(
    buildDigest({ expenseCount: 3, groupCount: 2, net: { INR: 120000, USD: -2550 } }),
    {
      title: "Your weekly PayPact digest",
      body: "3 new expenses across 2 groups · you're owed ₹1200 · you owe $25.50.",
    }
  );
  assert.equal(
    buildDigest({ expenseCount: 1, groupCount: 1, net: {} }).body,
    "1 new expense across 1 group."
  );
});

test("formatMoney", () => {
  assert.equal(formatMoney(-12345, "EUR"), "€123.45");
  assert.equal(formatMoney(5000, "XYZ"), "XYZ 50");
});
