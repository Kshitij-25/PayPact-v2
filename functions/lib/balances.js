"use strict";

/**
 * Pure balance maths shared by the weekly digest. Mirrors the sign convention
 * of the app's `computeNetBalances`: positive = the member is owed money,
 * negative = the member owes money. All arithmetic is in integer paise/cents.
 */

const toMinor = (v) => Math.round((Number(v) || 0) * 100);

/**
 * @param {Array<{amount:number, paidById:string, splits:Array<{userId:string, amount:number}>}>} expenses
 * @param {Array<{fromUserId:string, toUserId:string, amountPaise?:number, amount?:number}>} settlements
 * @param {string[]} memberIds
 * @returns {Record<string, number>} net balance per member in minor units
 */
function computeNetBalances(expenses, settlements, memberIds) {
  const net = {};
  for (const id of memberIds) net[id] = 0;
  const add = (id, v) => {
    if (id in net) net[id] += v;
  };

  for (const e of expenses) {
    add(e.paidById, toMinor(e.amount));
    for (const s of e.splits || []) add(s.userId, -toMinor(s.amount));
  }
  for (const s of settlements) {
    const minor =
      typeof s.amountPaise === "number" ? s.amountPaise : toMinor(s.amount);
    add(s.fromUserId, minor);
    add(s.toUserId, -minor);
  }
  return net;
}

const CURRENCY_SYMBOLS = {
  INR: "₹", USD: "$", EUR: "€", GBP: "£", JPY: "¥",
  AED: "AED ", SGD: "S$", AUD: "A$", CAD: "C$",
};

function formatMoney(minor, currency) {
  const sym = CURRENCY_SYMBOLS[currency] ?? `${currency} `;
  const whole = Math.abs(minor) / 100;
  const text = Number.isInteger(whole) ? whole.toString() : whole.toFixed(2);
  return `${sym}${text}`;
}

/**
 * Builds the digest line for one user.
 * @param {{expenseCount:number, groupCount:number, net:Record<string, number>}} summary
 *   `net` is keyed by currency code, in minor units.
 * @returns {{title:string, body:string}|null} null when there's nothing to say
 */
function buildDigest(summary) {
  const { expenseCount, groupCount, net } = summary;
  const owed = [];
  const owe = [];
  for (const [cur, minor] of Object.entries(net)) {
    if (minor >= 100) owed.push(formatMoney(minor, cur));
    else if (minor <= -100) owe.push(formatMoney(minor, cur));
  }
  if (expenseCount === 0 && owed.length === 0 && owe.length === 0) return null;

  const parts = [];
  if (expenseCount > 0) {
    parts.push(
      `${expenseCount} new expense${expenseCount === 1 ? "" : "s"} across ` +
        `${groupCount} group${groupCount === 1 ? "" : "s"}`
    );
  }
  if (owed.length) parts.push(`you're owed ${owed.join(" + ")}`);
  if (owe.length) parts.push(`you owe ${owe.join(" + ")}`);

  const body = parts.join(" · ");
  return {
    title: "Your weekly PayPact digest",
    body: body.charAt(0).toUpperCase() + body.slice(1) + ".",
  };
}

module.exports = { computeNetBalances, buildDigest, formatMoney, toMinor };
