"use strict";

/**
 * Per-group running summary, kept on the group document so the app can show
 * balances and totals without downloading every expense:
 *
 *   balances            { uid: net minor units }   (+ = is owed, - = owes)
 *   totalSpentMinor     sum of expense amounts
 *   expenseCount
 *   lastActivityAt / lastExpenseTitle
 *   summaryVersion      1 once the summary exists
 *
 * Triggers apply *deltas* (cheap, atomic via increment); `recompute` rebuilds
 * from scratch for backfill and for any group that has no summary yet.
 */

const { computeNetBalances, toMinor } = require("./balances");

const SUMMARY_VERSION = 1;

/** Net minor-unit contribution of one expense, per member. */
function expenseContribution(e) {
  const out = {};
  if (!e) return out;
  const add = (id, v) => {
    if (!id) return;
    out[id] = (out[id] || 0) + v;
  };
  add(e.paidById, toMinor(e.amount));
  for (const s of e.splits || []) add(s.userId, -toMinor(s.amount));
  return out;
}

function settlementContribution(s) {
  const out = {};
  if (!s) return out;
  const minor =
    typeof s.amountPaise === "number" ? s.amountPaise : toMinor(s.amount);
  if (s.fromUserId) out[s.fromUserId] = (out[s.fromUserId] || 0) + minor;
  if (s.toUserId) out[s.toUserId] = (out[s.toUserId] || 0) - minor;
  return out;
}

function diff(afterMap, beforeMap) {
  const out = {};
  for (const id of new Set([...Object.keys(afterMap), ...Object.keys(beforeMap)])) {
    const d = (afterMap[id] || 0) - (beforeMap[id] || 0);
    if (d !== 0) out[id] = d;
  }
  return out;
}

/**
 * What changed in the summary when an expense went from `before` to `after`
 * (either may be null for create / delete).
 */
function expenseDelta(before, after) {
  return {
    balances: diff(expenseContribution(after), expenseContribution(before)),
    totalSpentMinor: (after ? toMinor(after.amount) : 0) - (before ? toMinor(before.amount) : 0),
    expenseCount: (after ? 1 : 0) - (before ? 1 : 0),
  };
}

function settlementDelta(settlement) {
  return {
    balances: settlementContribution(settlement),
    totalSpentMinor: 0,
    expenseCount: 0,
  };
}

/** Full rebuild from every expense and settlement of a group. */
function buildSummary({ expenses, settlements, memberIds }) {
  const ids = new Set(memberIds);
  for (const e of expenses) {
    if (e.paidById) ids.add(e.paidById);
    for (const s of e.splits || []) ids.add(s.userId);
  }
  for (const s of settlements) {
    if (s.fromUserId) ids.add(s.fromUserId);
    if (s.toUserId) ids.add(s.toUserId);
  }
  const balances = computeNetBalances(expenses, settlements, [...ids]);

  let last = null;
  let lastTitle = "";
  for (const e of expenses) {
    const t = e.createdAt && e.createdAt.toMillis ? e.createdAt.toMillis() : 0;
    if (last === null || t >= last) {
      last = t;
      lastTitle = e.title || "";
    }
  }
  return {
    balances,
    totalSpentMinor: expenses.reduce((sum, e) => sum + toMinor(e.amount), 0),
    expenseCount: expenses.length,
    lastExpenseTitle: lastTitle,
    summaryVersion: SUMMARY_VERSION,
  };
}

module.exports = {
  SUMMARY_VERSION,
  expenseContribution,
  settlementContribution,
  expenseDelta,
  settlementDelta,
  buildSummary,
};
