/*
 * expenseController.js — Expense CRUD + balance calculation
 * These handlers can receive groupId/expenseId from URL params, query string,
 * or request body — the expenseOptions() helper resolves whichever is present.
 */
const {
  createExpense: createExpenseService,
  deleteExpense: deleteExpenseService,
  getBalances: getBalancesService,
  listExpenses: listExpensesService,
  recordSettlement: recordSettlementService,
  updateExpense: updateExpenseService,
} = require("../services/expenseService");

// Resolve groupId and expenseId from multiple possible sources (URL params, query, body)
function expenseOptions(req) {
  return {
    groupId: req.params.groupId || req.query.groupId || req.body?.groupId,
    expenseId: req.params.expenseId || req.query.expenseId || req.body?.expenseId,
  };
}

async function listExpenses(req, res, next) {
  try {
    const expenses = await listExpensesService(req.params.groupId);
    res.json(expenses);
  } catch (error) {
    next(error);
  }
}

async function createExpense(req, res, next) {
  try {
    const result = await createExpenseService(req.body, expenseOptions(req));
    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
}

async function updateExpense(req, res, next) {
  try {
    const result = await updateExpenseService(req.body, expenseOptions(req));
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function deleteExpense(req, res, next) {
  try {
    const result = await deleteExpenseService(expenseOptions(req));
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function getBalances(req, res, next) {
  try {
    const balances = await getBalancesService(req.params.groupId);
    res.json(balances);
  } catch (error) {
    next(error);
  }
}

async function recordSettlement(req, res, next) {
  try {
    const result = await recordSettlementService(req.body, req.params.groupId);
    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createExpense,
  deleteExpense,
  getBalances,
  listExpenses,
  recordSettlement,
  updateExpense,
};
