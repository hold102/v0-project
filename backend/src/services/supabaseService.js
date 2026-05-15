/*
 * supabaseService.js — Supabase PostgreSQL database layer
 *
 * Drop-in replacement for dbService.js. Exports the same readDb(), writeDb(),
 * updateDb(mutator) interface so no other service files need changes beyond
 * their import line.
 *
 * Internally uses Supabase tables + a stored procedure for atomic full-sync writes.
 * Field mapping: in-memory uses camelCase, tables use snake_case where noted.
 */

const supabase = require("../config/supabase");
const { createInitialDb } = require("../models/seedData");
const { clone, validateDb } = require("./dbValidator");

// A promise-based queue: each write waits for the previous one to finish
let updateQueue = Promise.resolve();

// Detect whether migration 002 has been applied (amount column exists).
// Cached after first probe to avoid hitting the DB on every read.
let splitAmountColumnAvailable = null;
async function probeSplitAmountColumn() {
  if (splitAmountColumnAvailable !== null) return splitAmountColumnAvailable;
  const probe = await supabase
    .from("expense_split_members")
    .select("amount")
    .limit(1);
  const missing =
    probe.error &&
    /column.*amount.*does not exist|amount.*does not exist/i.test(probe.error.message || "");
  if (missing) {
    splitAmountColumnAvailable = false;
    console.warn(
      "[supabaseService] expense_split_members.amount not found — migration 002_split_amounts.sql not applied. Custom split shares will be ignored until you run it."
    );
  } else {
    splitAmountColumnAvailable = true;
  }
  return splitAmountColumnAvailable;
}

// Map a Supabase account row (snake_case) to in-memory format (camelCase)
function accountToMemory(row) {
  return {
    userId: row.user_id,
    email: row.email,
    passwordHash: row.password_hash,
    salt: row.salt,
    createdAt: row.created_at,
  };
}

// Map a Supabase expense row (snake_case) to in-memory format (camelCase).
// splitAmounts is included only when at least one split row has an explicit amount.
function expenseToMemory(row, splitBetween, splitAmounts) {
  const expense = {
    id: row.id,
    description: row.description,
    amount: typeof row.amount === "number" ? row.amount : Number(row.amount),
    paidBy: row.paid_by,
    splitBetween,
    category: row.category,
    date: row.date,
    groupId: row.group_id,
    currency: row.currency || 'MYR',
  };
  if (splitAmounts && Object.keys(splitAmounts).length > 0) {
    expense.splitAmounts = splitAmounts;
  }
  return expense;
}

// Map a Supabase settlement row (snake_case) to in-memory format (camelCase)
function settlementToMemory(row) {
  return {
    id: row.id,
    from: row.from_user,
    to: row.to_user,
    amount: typeof row.amount === "number" ? row.amount : Number(row.amount),
    date: row.date,
    groupId: row.group_id,
  };
}

// Assemble the full in-memory database from Supabase tables
async function readDb() {
  // Decide split-members select based on whether migration 002 is applied.
  const hasAmount = await probeSplitAmountColumn();
  const splitMembersSelect = hasAmount
    ? "expense_id, user_id, amount"
    : "expense_id, user_id";

  // Query all tables in parallel
  const [
    { data: users, error: usersErr },
    { data: accounts, error: accountsErr },
    { data: appRows, error: appErr },
    { data: groupsRows, error: groupsErr },
    { data: groupMembers, error: gmErr },
    { data: expenses, error: expErr },
    { data: splitMembers, error: smErr },
    { data: settlements, error: settlementsErr },
  ] = await Promise.all([
    supabase.from("users").select("id, name, avatar, email, currency"),
    supabase.from("accounts").select("user_id, email, password_hash, salt, created_at"),
    supabase.from("app_state").select("current_user_id").limit(1),
    supabase.from("groups_table").select("id, name, emoji, description, created_at"),
    supabase.from("group_members").select("group_id, user_id"),
    supabase.from("expenses").select("id, description, amount, paid_by, category, date, group_id, currency"),
    supabase.from("expense_split_members").select(splitMembersSelect),
    supabase.from("settlements").select("id, group_id, from_user, to_user, amount, date"),
  ]);

  // If any query failed, throw (except for the case of empty tables on first run).
  // Tolerate a missing settlements table so the app works before the migration is applied.
  const settlementsTableMissing =
    settlementsErr && /settlements/i.test(settlementsErr.message || "") && /not find|does not exist|schema cache/i.test(settlementsErr.message || "");
  const blockingErrors = [usersErr, accountsErr, appErr, groupsErr, gmErr, expErr, smErr].filter(Boolean);
  if (settlementsErr && !settlementsTableMissing) blockingErrors.push(settlementsErr);
  if (blockingErrors.length > 0) {
    throw new Error(`Supabase query failed: ${blockingErrors.map((e) => e.message).join("; ")}`);
  }

  // Auto-seed on empty database (first run)
  if (!users || users.length === 0) {
    const db = createInitialDb();
    await writeDb(db);
    return clone(db);
  }

  // Build lookup maps
  const userMap = new Map(users.map((u) => [u.id, { id: u.id, name: u.name, avatar: u.avatar, email: u.email || undefined, currency: u.currency || 'MYR' }]));

  // Group members: Map<groupId, userId[]>
  const memberMap = new Map();
  (groupMembers || []).forEach((gm) => {
    if (!memberMap.has(gm.group_id)) memberMap.set(gm.group_id, []);
    memberMap.get(gm.group_id).push(gm.user_id);
  });

  // Expense split members: Map<expenseId, userId[]> + Map<expenseId, {userId: amount}>
  const splitMap = new Map();
  const splitAmountsMap = new Map();
  (splitMembers || []).forEach((sm) => {
    if (!splitMap.has(sm.expense_id)) splitMap.set(sm.expense_id, []);
    splitMap.get(sm.expense_id).push(sm.user_id);

    if (sm.amount !== null && sm.amount !== undefined) {
      if (!splitAmountsMap.has(sm.expense_id)) splitAmountsMap.set(sm.expense_id, {});
      splitAmountsMap.get(sm.expense_id)[sm.user_id] =
        typeof sm.amount === "number" ? sm.amount : Number(sm.amount);
    }
  });

  // Expenses by group: Map<groupId, expense[]>
  const expenseMap = new Map();
  (expenses || []).forEach((exp) => {
    const splitBetween = splitMap.get(exp.id) || [];
    const splitAmounts = splitAmountsMap.get(exp.id);
    const memExp = expenseToMemory(exp, splitBetween, splitAmounts);
    if (!expenseMap.has(exp.group_id)) expenseMap.set(exp.group_id, []);
    expenseMap.get(exp.group_id).push(memExp);
  });

  // Settlements by group: Map<groupId, settlement[]>
  const settlementMap = new Map();
  (settlements || []).forEach((s) => {
    if (!settlementMap.has(s.group_id)) settlementMap.set(s.group_id, []);
    settlementMap.get(s.group_id).push(settlementToMemory(s));
  });

  // Assemble groups with embedded members and expenses
  const groups = (groupsRows || []).map((g) => {
    const memberIds = memberMap.get(g.id) || [];
    const members = memberIds.map((uid) => {
      const user = userMap.get(uid);
      if (!user) throw new Error(`Group member ${uid} not found in users table.`);
      return { ...user };
    });

    return {
      id: g.id,
      name: g.name,
      emoji: g.emoji,
      description: g.description || '',
      members,
      expenses: expenseMap.get(g.id) || [],
      settlements: settlementMap.get(g.id) || [],
      createdAt: g.created_at,
    };
  });

  const currentUserId = appRows?.[0]?.current_user_id || (users[0] && users[0].id);

  const db = {
    currentUserId,
    users: users.map((u) => ({ id: u.id, name: u.name, avatar: u.avatar, email: u.email || undefined, currency: u.currency || 'MYR' })),
    groups,
    accounts: (accounts || []).map(accountToMemory),
  };

  return validateDb(db);
}

// Write the full in-memory database to Supabase via the atomic stored procedure
async function writeDb(db) {
  validateDb(db);

  // Map accounts from camelCase to the format expected by the stored procedure.
  // The procedure expects JSONB with camelCase field names matching in-memory format.
  // (The procedure internally maps to snake_case column names on INSERT.)

  const { error } = await supabase.rpc("sync_full_database", {
    p_current_user_id: db.currentUserId,
    p_users: db.users,
    p_accounts: db.accounts || [],
    p_groups: db.groups,
  });

  if (error) {
    throw new Error(`Supabase sync failed: ${error.message}`);
  }

  // Settlements are stored in a separate table the sync RPC doesn't know about.
  // Strategy: per-group delete-then-insert so the table mirrors in-memory state.
  // Skip silently if the table doesn't exist yet (migration not applied).
  await syncSettlements(db);
}

async function syncSettlements(db) {
  const rows = [];
  for (const group of db.groups) {
    for (const s of group.settlements || []) {
      rows.push({
        id: s.id,
        group_id: group.id,
        from_user: s.from,
        to_user: s.to,
        amount: s.amount,
        date: s.date,
      });
    }
  }

  const groupIds = db.groups.map((g) => g.id);
  if (groupIds.length > 0) {
    const { error: delErr } = await supabase
      .from("settlements")
      .delete()
      .in("group_id", groupIds);
    if (delErr) {
      if (/not find|does not exist|schema cache/i.test(delErr.message || "")) return;
      throw new Error(`Supabase settlement clear failed: ${delErr.message}`);
    }
  }

  if (rows.length > 0) {
    const { error: insErr } = await supabase.from("settlements").insert(rows);
    if (insErr) {
      if (/not find|does not exist|schema cache/i.test(insErr.message || "")) return;
      throw new Error(`Supabase settlement insert failed: ${insErr.message}`);
    }
  }
}

// The main write API: read → mutate → write, serialised through a queue
async function updateDb(mutator) {
  const run = async () => {
    const db = await readDb();
    const result = await mutator(db);  // mutator modifies db in-place
    await writeDb(db);
    return clone(result);  // Return a snapshot so callers can't mutate the DB
  };

  // Chain onto the queue so writes never overlap
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
