/*
 * summaryController.js — Per-user totals across all groups
 * GET / returns { totalOwed, totalOwing } for the current user, computed by
 * summing the simplified settlement plan across every group they belong to.
 */
const { readDb } = require("../services/supabaseService");
const { calculateBalancesForGroup } = require("../services/expenseService");

function round2(n) {
  return Math.round(n * 100) / 100;
}

async function getSummary(_req, res, next) {
  try {
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

    res.json({
      currentUserId: me,
      totalOwed: round2(totalOwed),
      totalOwing: round2(totalOwing),
      net: round2(totalOwed - totalOwing),
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getSummary,
};
