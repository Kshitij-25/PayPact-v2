"use strict";

// Server-side mirror of lib/features/notification/domain/notification_prefs.dart
// (the client applies the same rule when it writes a notification).

const DEFAULTS = { settlements: true, nudges: true, expenses: true, digest: false };

function categoryFor(type) {
  switch (type) {
    case "expense_added":
    case "expense_updated":
    case "expense_deleted":
    case "expense_comment":
      return "expenses";
    case "settlement":
      return "settlements";
    case "nudge":
      return "nudges";
    case "digest":
      return "digest";
    default:
      return null;
  }
}

function shouldDeliver(type, groupId, userData) {
  const category = categoryFor(type);
  if (!category) return true;
  const prefs = userData && userData.notifPrefs;
  const enabled =
    prefs && typeof prefs[category] === "boolean" ? prefs[category] : DEFAULTS[category];
  if (!enabled) return false;
  const muted = userData && userData.mutedGroups;
  if (groupId && Array.isArray(muted) && muted.includes(groupId)) return false;
  return true;
}

module.exports = { shouldDeliver, categoryFor, DEFAULTS };
