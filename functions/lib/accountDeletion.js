"use strict";

/**
 * Decides what deleting an account means for each group the user is in.
 * Pure so it can be tested; the callable applies the plan.
 *
 * @param {string} uid
 * @param {Array<{id:string,name:string,currency:string,memberIds:string[],
 *   adminIds:string[], createdBy:string, netMinor:number}>} groups
 * @returns {{blockers: Array<{groupId,name,currency,netMinor}>,
 *   actions: Array<{type:'delete_group'|'leave', groupId:string, name:string,
 *   promote?: string}>}}
 */
function planAccountDeletion(uid, groups) {
  const blockers = [];
  const actions = [];

  for (const g of groups) {
    const others = g.memberIds.filter((m) => m !== uid);

    // A group of one disappears with its only member, whatever the balance.
    if (others.length === 0) {
      actions.push({ type: "delete_group", groupId: g.id, name: g.name });
      continue;
    }

    // Leaving with a balance would strand money and break the group's books.
    if (g.netMinor !== 0) {
      blockers.push({
        groupId: g.id,
        name: g.name,
        currency: g.currency,
        netMinor: g.netMinor,
      });
      continue;
    }

    const admins = g.adminIds && g.adminIds.length ? g.adminIds : [g.createdBy];
    const otherAdmins = admins.filter((a) => a !== uid && others.includes(a));
    const action = { type: "leave", groupId: g.id, name: g.name };
    // Sole admin: hand the group to the longest-standing remaining member.
    if (admins.includes(uid) && otherAdmins.length === 0) action.promote = others[0];
    actions.push(action);
  }

  return { blockers, actions };
}

module.exports = { planAccountDeletion };
