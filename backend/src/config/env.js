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
  port: Number.isFinite(port) ? port : 5001,
  supabaseUrl: process.env.SUPABASE_URL,
  supabaseSecretKey: process.env.SUPABASE_SECRET_KEY,
  brevoApiKey: process.env.BREVO_API_KEY || null,
  // Base URL used to build the verification link in emails (no trailing slash)
  appBaseUrl: process.env.APP_BASE_URL || `http://localhost:5001`,
};
