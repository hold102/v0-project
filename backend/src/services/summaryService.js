/*
 * summaryService.js — Per-user balance totals across all groups
 *
 * Computes how much the current user is owed and how much they owe, by
 * summing the simplified settlement plan across every group they belong to.
 */
const { readDb } = require("./supabaseService");
const { calculateBalancesForGroup } = require("./expenseService");

function round2(n) {
  return Math.round(n * 100) / 100;
}

async function getSummary() {
  const db = await readDb();
  const me = db.currentUserId;

  let totalOwed = 0;
  let totalOwing = 0;

  for (const group of db.groups) {
    if (!group.members.some((m) => m.id === me)) continue;
    const balances = calculateBalancesForGroup(group);
    for (const b of balances) {
      if (b.to === me) totalOwed += b.amount;
      if (b.from === me) totalOwing += b.amount;
    }
  }

  return {
    currentUserId: me,
    totalOwed: round2(totalOwed),
    totalOwing: round2(totalOwing),
    net: round2(totalOwed - totalOwing),
  };
}

module.exports = {
  getSummary,
};
