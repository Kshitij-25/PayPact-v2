"use strict";

/**
 * Recurring expenses are templates under groups/{gid}/recurring. A daily job
 * turns every due template into real expenses and moves `nextRunAt` forward.
 */

const MAX_CATCH_UP = 12; // never create more than a year of monthly backlog at once

/** The next date after [from] for [interval] ('weekly' | 'monthly'). */
function nextOccurrence(from, interval) {
  const d = new Date(from.getTime());
  if (interval === "weekly") {
    d.setUTCDate(d.getUTCDate() + 7);
    return d;
  }
  // monthly: same day next month, clamped (Jan 31 -> Feb 28/29)
  const day = d.getUTCDate();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + 1);
  const lastDay = new Date(
    Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)
  ).getUTCDate();
  d.setUTCDate(Math.min(day, lastDay));
  return d;
}

/**
 * Occurrences due up to [now] starting at [nextRunAt], plus the new nextRunAt.
 * @returns {{due: Date[], next: Date}}
 */
function dueOccurrences(nextRunAt, interval, now) {
  const due = [];
  let cursor = new Date(nextRunAt.getTime());
  while (cursor.getTime() <= now.getTime() && due.length < MAX_CATCH_UP) {
    due.push(new Date(cursor.getTime()));
    cursor = nextOccurrence(cursor, interval);
  }
  // If we hit the cap, skip the remaining backlog rather than flood the group.
  while (cursor.getTime() <= now.getTime()) {
    cursor = nextOccurrence(cursor, interval);
  }
  return { due, next: cursor };
}

module.exports = { nextOccurrence, dueOccurrences, MAX_CATCH_UP };
