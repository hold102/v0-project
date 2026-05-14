/*
 * env.js — Environment configuration
 * Reads the server port and JSON database file path from environment variables,
 * falling back to sensible defaults when they are not set.
 *
 * PORT       — the TCP port the server listens on (default: 3000)

 */
require("dotenv").config();

// Parse the PORT env variable as an integer, default to 5001
const port = Number.parseInt(process.env.PORT || "5001", 10);

module.exports = {
  // Guard against NaN (e.g. PORT="abc")
  port: Number.isFinite(port) ? port : 5001,

  //Supabase config
  supabaseUrl: process.env.SUPABASE_URL,
  supabaseSecretKey: process.env.SUPABASE_SECRET_KEY,
};
