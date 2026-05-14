/*
 * dbValidator.js — Data integrity validators shared by dbService and supabaseService.
 * These run on every database read and write to guarantee structural correctness.
 */

const { isExpenseCategory } = require("../models/categoryModel");

// Deep-clone via JSON round-trip (fast enough for our data sizes)
function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

// Throws if value is not a non-empty string
function assertString(value, message) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(message);
  }
}

// --- Data validators (run on every read/write) ---

function validateUser(user) {
  if (!isObject(user)) throw new Error("Invalid user.");
  assertString(user.id, "User id is required.");
  assertString(user.name, "User name is required.");
  assertString(user.avatar, "User avatar is required.");
  if (user.email !== undefined && typeof user.email !== "string") {
    throw new Error("User email must be text.");
  }
}

function validateAccount(account, userIds) {
  if (!isObject(account)) throw new Error("Invalid account.");
  assertString(account.userId, "Account user id is required.");
  assertString(account.email, "Account email is required.");
  assertString(account.passwordHash, "Account password hash is required.");
  assertString(account.salt, "Account salt is required.");
  assertString(account.createdAt, "Account created date is required.");
  if (!userIds.has(account.userId)) {
    throw new Error("Account user does not exist.");
  }
}

function validateExpense(expense) {
  if (!isObject(expense)) throw new Error("Invalid expense.");
  assertString(expense.id, "Expense id is required.");
  assertString(expense.description, "Expense description is required.");
  if (typeof expense.amount !== "number" || !Number.isFinite(expense.amount) || expense.amount <= 0) {
    throw new Error("Expense amount must be positive.");
  }
  assertString(expense.paidBy, "Expense payer is required.");
  if (!Array.isArray(expense.splitBetween) || expense.splitBetween.length === 0) {
    throw new Error("Expense split members are required.");
  }
  expense.splitBetween.forEach((userId) => assertString(userId, "Split member id is required."));
  if (!isExpenseCategory(expense.category)) {
    throw new Error("Expense category is invalid.");
  }
  assertString(expense.date, "Expense date is required.");
  assertString(expense.groupId, "Expense group id is required.");
}

function validateSettlement(settlement) {
  if (!isObject(settlement)) throw new Error("Invalid settlement.");
  assertString(settlement.id, "Settlement id is required.");
  assertString(settlement.from, "Settlement from is required.");
  assertString(settlement.to, "Settlement to is required.");
  if (typeof settlement.amount !== "number" || !Number.isFinite(settlement.amount) || settlement.amount <= 0) {
    throw new Error("Settlement amount must be positive.");
  }
  assertString(settlement.date, "Settlement date is required.");
}

function validateGroup(group) {
  if (!isObject(group)) throw new Error("Invalid group.");
  assertString(group.id, "Group id is required.");
  assertString(group.name, "Group name is required.");
  assertString(group.emoji, "Group emoji is required.");
  if (!Array.isArray(group.members) || group.members.length === 0) {
    throw new Error("Group members are required.");
  }
  if (!Array.isArray(group.expenses)) {
    throw new Error("Group expenses must be a list.");
  }
  if (!Array.isArray(group.settlements)) {
    throw new Error("Group settlements must be a list.");
  }
  assertString(group.createdAt, "Group created date is required.");
  // Cascade: validate every member, expense, and settlement inside the group
  group.members.forEach(validateUser);
  group.expenses.forEach(validateExpense);
  group.settlements.forEach(validateSettlement);
  // Cross-check: settlement participants must be group members
  const memberIds = new Set(group.members.map((m) => m.id));
  group.settlements.forEach((s) => {
    if (!memberIds.has(s.from)) throw new Error("Settlement from is not a group member.");
    if (!memberIds.has(s.to)) throw new Error("Settlement to is not a group member.");
  });
}

// Top-level DB integrity check — runs on every readDb() and writeDb()
function validateDb(db) {
  if (!isObject(db)) throw new Error("Invalid database.");
  assertString(db.currentUserId, "Current user id is required.");
  if (!Array.isArray(db.users) || db.users.length === 0) {
    throw new Error("Users are required.");
  }
  if (!Array.isArray(db.groups)) {
    throw new Error("Groups must be a list.");
  }

  db.users.forEach(validateUser);
  db.groups.forEach(validateGroup);

  const userIds = new Set(db.users.map((user) => user.id));
  if (!userIds.has(db.currentUserId)) {
    throw new Error("Current user does not exist.");
  }

  if (db.accounts !== undefined) {
    if (!Array.isArray(db.accounts)) {
      throw new Error("Accounts must be a list.");
    }
    db.accounts.forEach((account) => validateAccount(account, userIds));
  }

  // Cross-reference checks: every group member must be a real user,
  // every expense's payer/split members must belong to the group
  db.groups.forEach((group) => {
    const memberIds = new Set(group.members.map((member) => member.id));
    group.members.forEach((member) => {
      if (!userIds.has(member.id)) {
        throw new Error("Group member does not exist in users.");
      }
    });

    group.expenses.forEach((expense) => {
      if (expense.groupId !== group.id) {
        throw new Error("Expense group id does not match parent group.");
      }
      if (!memberIds.has(expense.paidBy)) {
        throw new Error("Expense payer is not a group member.");
      }
      expense.splitBetween.forEach((userId) => {
        if (!memberIds.has(userId)) {
          throw new Error("Expense split member is not a group member.");
        }
      });
    });
  });

  return db;
}

module.exports = {
  clone,
  isObject,
  assertString,
  validateUser,
  validateAccount,
  validateExpense,
  validateSettlement,
  validateGroup,
  validateDb,
};
