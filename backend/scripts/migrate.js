/*
 * migrate.js — Apply SQL migrations to the Supabase Postgres database.
 *
 * Usage:
 *   DATABASE_URL=postgresql://... node scripts/migrate.js
 *   npm run migrate
 *
 * Reads every .sql file in src/db/migrations/ in lexical order and executes it
 * as a single statement batch. Migrations must be idempotent (use IF NOT EXISTS,
 * CREATE OR REPLACE, etc.) — this runner does not track applied state.
 *
 * DATABASE_URL is the Supabase Postgres connection string:
 *   Dashboard -> Project Settings -> Database -> Connection string (URI mode).
 */

require("dotenv").config();
const fs = require("fs");
const path = require("path");
const { Client } = require("pg");

const MIGRATIONS_DIR = path.join(__dirname, "..", "src", "db", "migrations");

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error("DATABASE_URL is not set. Add it to backend/.env (see .env.example).");
    process.exit(1);
  }

  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((name) => name.endsWith(".sql"))
    .sort();

  if (files.length === 0) {
    console.log("No migrations found.");
    return;
  }

  const client = new Client({ connectionString });
  await client.connect();

  try {
    for (const file of files) {
      const fullPath = path.join(MIGRATIONS_DIR, file);
      const sql = fs.readFileSync(fullPath, "utf8");
      process.stdout.write(`Applying ${file} ... `);
      await client.query(sql);
      console.log("ok");
    }
    console.log(`Applied ${files.length} migration(s).`);
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error("Migration failed:", err.message);
  process.exit(1);
});
