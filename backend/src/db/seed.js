/*
 * seed.js — Seed the Supabase database from existing app-db.json (or defaults)
 *
 * Usage:
 *   node src/db/seed.js              — seed from existing data or defaults
 *   node src/db/seed.js --reset      — force re-seed with initial defaults
 *
 * This script reads the existing JSON database (if present) and writes it to
 * Supabase via the sync_full_database stored procedure.
 */

const fs = require("fs");
const path = require("path");
require("dotenv").config();
const supabase = require("../../src/config/supabase");
const { createInitialDb } = require("../models/seedData");
const { validateDb } = require("../services/dbValidator");

const dataFile = path.join(__dirname, "..", "..", "data", "app-db.json");

function readJsonFile() {
  try {
    const raw = fs.readFileSync(dataFile, "utf8");
    const db = JSON.parse(raw);
    return validateDb(db);
  } catch (err) {
    if (err.code === "ENOENT") return null;
    throw err;
  }
}

async function seed() {
  const forceReset = process.argv.includes("--reset");
  const existing = forceReset ? null : readJsonFile();
  const db = existing || createInitialDb();

  console.log(existing
    ? `Seeding Supabase with existing data (${db.users.length} users, ${db.groups.length} groups)...`
    : "Seeding Supabase with initial defaults (1 user, 0 groups)...");

  const { error } = await supabase.rpc("sync_full_database", {
    p_current_user_id: db.currentUserId,
    p_users: db.users,
    p_accounts: db.accounts || [],
    p_groups: db.groups,
  });

  if (error) {
    console.error("Seed failed:", error.message);
    process.exit(1);
  }

  console.log("Database seeded successfully.");
  process.exit(0);
}

seed().catch((err) => {
  console.error("Fatal error:", err.message);
  process.exit(1);
});
