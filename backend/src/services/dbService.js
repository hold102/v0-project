const fs = require("fs/promises");
const path = require("path");
const { dataFile } = require("../config/env");
const { isExpenseCategory } = require("../models/categoryModel");
const { createInitialDb } = require("../models/seedData");

let updateQueue = Promise.resolve();

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function assertString(value, message) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(message);
  }
}

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
  assertString(group.createdAt, "Group created date is required.");
  group.members.forEach(validateUser);
  group.expenses.forEach(validateExpense);
}

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

async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function readJson(filePath) {
  const file = await fs.readFile(filePath, "utf8");
  return JSON.parse(file);
}

async function readDb() {
  if (await fileExists(dataFile)) {
    return validateDb(await readJson(dataFile));
  }

  const db = createInitialDb();
  await writeDb(db);
  return clone(db);
}

async function writeDb(db) {
  validateDb(db);
  await fs.mkdir(path.dirname(dataFile), { recursive: true });
  const tempPath = `${dataFile}.${process.pid}.${Date.now()}.${Math.random().toString(36).slice(2)}.tmp`;
  await fs.writeFile(tempPath, `${JSON.stringify(db, null, 2)}\n`, "utf8");
  await fs.rename(tempPath, dataFile);
}

async function updateDb(mutator) {
  const run = async () => {
    const db = await readDb();
    const result = await mutator(db);
    await writeDb(db);
    return clone(result);
  };

  const nextUpdate = updateQueue.then(run, run);
  updateQueue = nextUpdate.then(
    () => undefined,
    () => undefined
  );
  return nextUpdate;
}

module.exports = {
  readDb,
  writeDb,
  updateDb,
};
