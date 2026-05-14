const { createId, todayIsoDate } = require("./idService");
const { readDb, updateDb } = require("./dbService");
const { isExpenseCategory } = require("../models/categories");
const { RequestError } = require("../models/requestError");

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeOptionalId(value, label) {
  if (value === undefined) return undefined;
  const id = normalizeText(value);
  if (!id) {
    throw new RequestError(`${label} must be text.`);
  }
  return id;
}

function normalizeExpenseSource(body) {
  if (!isObject(body)) {
    throw new RequestError("Expense payload is required.");
  }
  return isObject(body.expense) ? body.expense : body;
}

function normalizeGroupId(groupId) {
  const id = normalizeText(groupId);
  if (!id) {
    throw new RequestError("Group id is required.");
  }
  return id;
}

function normalizeExpenseId(expenseId) {
  const id = normalizeText(expenseId);
  if (!id) {
    throw new RequestError("Expense id is required.");
  }
  return id;
}

function validateAmount(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new RequestError("Expense amount must be a positive number.");
  }
  return Math.round(value * 100) / 100;
}

function validateSplitMembers(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new RequestError("At least one split member is required.");
  }

  if (!value.every((userId) => typeof userId === "string" && userId.trim())) {
    throw new RequestError("All split members must be valid user ids.");
  }

  const splitBetween = value.map((userId) => userId.trim());
  if (new Set(splitBetween).size !== splitBetween.length) {
    throw new RequestError("Split members must be unique.");
  }

  return splitBetween;
}

function getVisibleGroup(db, groupId) {
  const group = db.groups.find((item) => item.id === groupId);
  if (!group) {
    throw new RequestError("Group not found.", 404);
  }

  const isMember = group.members.some((member) => member.id === db.currentUserId);
  if (!isMember) {
    throw new RequestError("Group not found.", 404);
  }

  return group;
}

function assertExpenseUsersBelongToGroup(group, paidBy, splitBetween) {
  const groupMemberIds = new Set(group.members.map((member) => member.id));

  if (!groupMemberIds.has(paidBy) || splitBetween.some((id) => !groupMemberIds.has(id))) {
    throw new RequestError("Payer and split members must belong to the group.");
  }
}

function normalizeCreateExpense(body, groupIdFromParams) {
  const source = normalizeExpenseSource(body);
  const groupId = normalizeGroupId(groupIdFromParams || body.groupId);
  const description = normalizeText(source.description);
  const paidBy = normalizeText(source.paidBy);
  const splitBetween = validateSplitMembers(source.splitBetween);
  const category = normalizeText(source.category);

  if (!description) {
    throw new RequestError("Expense description is required.");
  }

  if (!paidBy) {
    throw new RequestError("Payer is required.");
  }

  if (!isExpenseCategory(category)) {
    throw new RequestError("Expense category is invalid.");
  }

  return {
    id: normalizeOptionalId(source.id || body.id, "Expense id"),
    groupId,
    description,
    amount: validateAmount(source.amount),
    paidBy,
    splitBetween,
    category,
    date: normalizeText(source.date) || todayIsoDate(),
  };
}

function normalizeUpdateExpense(body) {
  if (!isObject(body)) {
    throw new RequestError("Expense payload is required.");
  }

  const source = normalizeExpenseSource(body);
  const updates = {};

  if (source.description !== undefined) {
    const description = normalizeText(source.description);
    if (!description) throw new RequestError("Expense description is required.");
    updates.description = description;
  }

  if (source.amount !== undefined) {
    updates.amount = validateAmount(source.amount);
  }

  if (source.paidBy !== undefined) {
    const paidBy = normalizeText(source.paidBy);
    if (!paidBy) throw new RequestError("Payer is required.");
    updates.paidBy = paidBy;
  }

  if (source.splitBetween !== undefined) {
    updates.splitBetween = validateSplitMembers(source.splitBetween);
  }

  if (source.category !== undefined) {
    const category = normalizeText(source.category);
    if (!isExpenseCategory(category)) {
      throw new RequestError("Expense category is invalid.");
    }
    updates.category = category;
  }

  if (source.date !== undefined) {
    const date = normalizeText(source.date);
    if (!date) throw new RequestError("Expense date is required.");
    updates.date = date;
  }

  return updates;
}

function calculateBalancesForGroup(group) {
  const balanceMap = new Map(group.members.map((member) => [member.id, 0]));

  group.expenses.forEach((expense) => {
    const splitAmount = expense.amount / expense.splitBetween.length;
    balanceMap.set(expense.paidBy, (balanceMap.get(expense.paidBy) || 0) + expense.amount);
    expense.splitBetween.forEach((userId) => {
      balanceMap.set(userId, (balanceMap.get(userId) || 0) - splitAmount);
    });
  });

  const debtors = [];
  const creditors = [];

  balanceMap.forEach((balance, userId) => {
    if (balance < -0.01) debtors.push({ userId, amount: -balance });
    if (balance > 0.01) creditors.push({ userId, amount: balance });
  });

  debtors.sort((a, b) => b.amount - a.amount);
  creditors.sort((a, b) => b.amount - a.amount);

  const settlements = [];
  let i = 0;
  let j = 0;

  while (i < debtors.length && j < creditors.length) {
    const amount = Math.min(debtors[i].amount, creditors[j].amount);
    if (amount > 0.01) {
      settlements.push({
        from: debtors[i].userId,
        to: creditors[j].userId,
        amount: Math.round(amount * 100) / 100,
      });
    }

    debtors[i].amount -= amount;
    creditors[j].amount -= amount;
    if (debtors[i].amount < 0.01) i += 1;
    if (creditors[j].amount < 0.01) j += 1;
  }

  return settlements;
}

async function listExpenses(groupId) {
  const db = await readDb();
  const group = getVisibleGroup(db, normalizeGroupId(groupId));
  return group.expenses;
}

async function createExpense(body, options = {}) {
  const expenseData = normalizeCreateExpense(body, options.groupId);

  return updateDb((db) => {
    const group = getVisibleGroup(db, expenseData.groupId);
    assertExpenseUsersBelongToGroup(group, expenseData.paidBy, expenseData.splitBetween);

    const expense = {
      id: expenseData.id || createId("e"),
      description: expenseData.description,
      amount: expenseData.amount,
      paidBy: expenseData.paidBy,
      splitBetween: expenseData.splitBetween,
      category: expenseData.category,
      date: expenseData.date,
      groupId: group.id,
    };

    if (group.expenses.some((item) => item.id === expense.id)) {
      throw new RequestError("Expense id already exists.", 409);
    }

    group.expenses.push(expense);
    return { group, expense };
  });
}

async function updateExpense(body, options = {}) {
  const groupId = normalizeGroupId(options.groupId || body?.groupId);
  const expenseId = normalizeExpenseId(options.expenseId || body?.expenseId);
  const updates = normalizeUpdateExpense(body);

  return updateDb((db) => {
    const group = getVisibleGroup(db, groupId);
    const expense = group.expenses.find((item) => item.id === expenseId);
    if (!expense) {
      throw new RequestError("Expense not found.", 404);
    }

    const nextExpense = { ...expense, ...updates };
    assertExpenseUsersBelongToGroup(group, nextExpense.paidBy, nextExpense.splitBetween);

    Object.assign(expense, updates);
    return { group, expense };
  });
}

async function deleteExpense(options = {}) {
  const groupId = normalizeGroupId(options.groupId);
  const expenseId = normalizeExpenseId(options.expenseId);

  return updateDb((db) => {
    const group = getVisibleGroup(db, groupId);
    const index = group.expenses.findIndex((expense) => expense.id === expenseId);

    if (index === -1) {
      throw new RequestError("Expense not found.", 404);
    }

    const [expense] = group.expenses.splice(index, 1);
    return { group, expense };
  });
}

async function getBalances(groupId) {
  const db = await readDb();
  const group = getVisibleGroup(db, normalizeGroupId(groupId));
  return calculateBalancesForGroup(group);
}

module.exports = {
  createExpense,
  deleteExpense,
  getBalances,
  listExpenses,
  updateExpense,
};
