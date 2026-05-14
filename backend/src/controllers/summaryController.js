/*
 * summaryController.js — Per-user totals across all groups
 * GET / returns { totalOwed, totalOwing } for the current user, computed by
 * summing the simplified settlement plan across every group they belong to.
 */
const { getSummary: getSummaryService } = require("../services/summaryService");

async function getSummary(_req, res, next) {
  try {
    const result = await getSummaryService();
    res.json(result);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getSummary,
};
