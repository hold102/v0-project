const {
  createExpense: createExpenseService,
  deleteExpense: deleteExpenseService,
  getBalances: getBalancesService,
  listExpenses: listExpensesService,
  updateExpense: updateExpenseService,
} = require("../services/expenseService");

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

module.exports = {
  createExpense,
  deleteExpense,
  getBalances,
  listExpenses,
  updateExpense,
};
