/*
 * expenseService.js — Expense business logic
 *
 * Responsibilities:
 *   - Validate and normalise expense input (amount, payer, split members, category...)
 *   - Enforce access control: only group members can see/modify expenses
 *   - Calculate group balances (who owes whom)
 *
 * Balance calculation uses a simple greedy settlement algorithm:
 *   1. Compute net balance for each member
 *   2. Sort debtors (largest debt first) and creditors (largest credit first)
 *   3. Greedily pair them up, producing a list of "A pays B $X" settlements
 */

const { createId, todayIsoDate } = require("./idService");
const { readDb, updateDb } = require("./supabaseService");
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

// Expenses can be sent as { expense: {...} } or as a flat object — normalise here
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

// Validate and round amount to 2 decimal places (cents)
function validateAmount(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new RequestError("Expense amount must be a positive number.");
  }
  return Math.round(value * 100) / 100;
}

// Validate the splitBetween array: non-empty, all valid IDs, no duplicates
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

// Validate optional per-member dollar amounts for an unequal split.
// Returns either an object keyed by userId, or undefined if the caller did
// not provide custom amounts (meaning equal split).
function validateSplitAmounts(raw, splitBetween, totalAmount) {
  if (raw === undefined || raw === null) return undefined;
  if (!isObject(raw)) {
    throw new RequestError("splitAmounts must be an object keyed by user id.");
  }
  const keys = Object.keys(raw);
  if (keys.length === 0) return undefined;

  const splitSet = new Set(splitBetween);
  const cleaned = {};
  let total = 0;
  for (const userId of keys) {
    if (!splitSet.has(userId)) {
      throw new RequestError(`splitAmounts contains user id ${userId} not in splitBetween.`);
    }
    const amount = raw[userId];
    if (typeof amount !== "number" || !Number.isFinite(amount) || amount < 0) {
      throw new RequestError("splitAmounts values must be non-negative numbers.");
    }
    const rounded = Math.round(amount * 100) / 100;
    cleaned[userId] = rounded;
    total += rounded;
  }

  if (keys.length !== splitBetween.length) {
    throw new RequestError("splitAmounts must cover every split member.");
  }

  if (Math.abs(total - totalAmount) > 0.01) {
    throw new RequestError(
      `splitAmounts must sum to the expense amount (got ${total.toFixed(2)}, expected ${totalAmount.toFixed(2)}).`
    );
  }

  return cleaned;
}

// Fetch a group by ID, ensuring the current user is a member.
// Returns the same error (404) for non-existent groups and non-member access
// to avoid leaking information about groups the user doesn't belong to.
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
  const amount = validateAmount(source.amount);
  const splitAmounts = validateSplitAmounts(source.splitAmounts, splitBetween, amount);

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
    amount,
    paidBy,
    splitBetween,
    splitAmounts,
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

  // splitAmounts is validated lazily in updateExpense once we have the
  // final amount + splitBetween (it depends on both).
  if (source.splitAmounts !== undefined) {
    updates._splitAmountsRaw = source.splitAmounts;
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

// Greedy settlement algorithm: for each group member, compute net balance =
// (total paid) - (total share). Then pair largest debtor with largest creditor
// until all balances are settled to within 1 cent.
function calculateBalancesForGroup(group) {
  // Initialise every member's balance to 0
  const balanceMap = new Map(group.members.map((member) => [member.id, 0]));

  group.expenses.forEach((expense) => {
    // The payer gets credited the full amount
    balanceMap.set(expense.paidBy, (balanceMap.get(expense.paidBy) || 0) + expense.amount);

    // Per-member share: explicit amount if splitAmounts is set, else equal split
    const equalShare = expense.amount / expense.splitBetween.length;
    expense.splitBetween.forEach((userId) => {
      const share = expense.splitAmounts && typeof expense.splitAmounts[userId] === "number"
        ? expense.splitAmounts[userId]
        : equalShare;
      balanceMap.set(userId, (balanceMap.get(userId) || 0) - share);
    });
  });

  const debtors = [];
  const creditors = [];

  // Separate into debtors (negative balance) and creditors (positive balance)
  // 0.01 threshold avoids floating-point noise
  balanceMap.forEach((balance, userId) => {
    if (balance < -0.01) debtors.push({ userId, amount: -balance });
    if (balance > 0.01) creditors.push({ userId, amount: balance });
  });

  // Sort descending so we settle the largest amounts first
  debtors.sort((a, b) => b.amount - a.amount);
  creditors.sort((a, b) => b.amount - a.amount);

  const settlements = [];
  let i = 0;
  let j = 0;

  // Greedy pairing: largest debtor pays largest creditor
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
  return group.expenses.filter((e) => e.category !== "settlement");
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
      splitAmounts: expenseData.splitAmounts,  // undefined = equal split
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

    const { _splitAmountsRaw, ...directUpdates } = updates;
    const nextExpense = { ...expense, ...directUpdates };
    assertExpenseUsersBelongToGroup(group, nextExpense.paidBy, nextExpense.splitBetween);

    // Resolve splitAmounts against whichever amount + splitBetween end up effective.
    if (_splitAmountsRaw !== undefined) {
      directUpdates.splitAmounts = validateSplitAmounts(
        _splitAmountsRaw,
        nextExpense.splitBetween,
        nextExpense.amount
      );
    } else if (
      (directUpdates.splitBetween !== undefined || directUpdates.amount !== undefined) &&
      expense.splitAmounts
    ) {
      // If split membership or amount changed but caller didn't send a new
      // splitAmounts, drop the stale custom amounts (caller must re-supply).
      directUpdates.splitAmounts = undefined;
    }

    Object.assign(expense, directUpdates);
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

async function recordSettlement(body, groupId) {
  const gid = normalizeGroupId(groupId);
  const from = normalizeText(body?.from);
  const to = normalizeText(body?.to);
  const amount = validateAmount(body?.amount);
  const date = typeof body?.date === "string" && body.date.trim() ? body.date.trim() : todayIsoDate();

  if (!from || !to) throw new RequestError("Both from and to user IDs are required.");
  if (from === to) throw new RequestError("Cannot settle with yourself.", 400);

  // Store settlement as a special expense: payer (from) paid the creditor (to).
  // This naturally balances the books — from gets +credit, to gets -debit.
  return updateDb((db) => {
    const group = getVisibleGroup(db, gid);

    const memberIds = new Set(group.members.map((m) => m.id));
    if (!memberIds.has(from)) throw new RequestError("Payer is not a group member.", 400);
    if (!memberIds.has(to)) throw new RequestError("Recipient is not a group member.", 400);

    const expense = {
      id: createId("e"),
      description: "Settlement",
      amount,
      paidBy: from,
      splitBetween: [to],
      category: "settlement",
      date,
      groupId: gid,
    };

    group.expenses.push(expense);
    return { group, expense };
  });
}

module.exports = {
  calculateBalancesForGroup,
  createExpense,
  deleteExpense,
  getBalances,
  listExpenses,
  recordSettlement,
  updateExpense,
};
