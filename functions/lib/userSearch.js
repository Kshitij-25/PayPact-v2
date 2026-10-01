"use strict";

function maskEmail(email) {
  if (!email || !email.includes("@")) return "";
  const [local, domain] = email.split("@");
  return `${local.slice(0, 1)}${"•".repeat(Math.max(1, Math.min(local.length - 1, 4)))}@${domain}`;
}

/** Classifies a search query: exact email lookup vs. name prefix. */
function classifyQuery(raw) {
  const q = String(raw || "").trim().toLowerCase();
  if (q.length < 2) return { kind: "none", q };
  if (q.includes("@")) return { kind: "email", q };
  return { kind: "name", q };
}

module.exports = { maskEmail, classifyQuery };
