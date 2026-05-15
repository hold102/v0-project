/*
 * verificationService.js — Email verification token management
 * Uses a standalone `email_verifications` Supabase table (not part of sync RPC).
 * Legacy accounts with no row are treated as verified.
 */
const crypto = require("crypto");
const supabase = require("../config/supabase");

function generateToken() {
  return crypto.randomBytes(32).toString("hex");
}

async function createVerificationToken(userId) {
  const token = generateToken();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(); // 24 hours

  const { error } = await supabase
    .from("email_verifications")
    .upsert({ user_id: userId, token, expires_at: expiresAt, verified_at: null }, { onConflict: "user_id" });

  if (error) throw new Error(`Failed to create verification token: ${error.message}`);
  return token;
}

// Returns true if verified OR if no row exists (legacy/pre-verification account)
async function isVerified(userId) {
  const { data, error } = await supabase
    .from("email_verifications")
    .select("verified_at")
    .eq("user_id", userId)
    .maybeSingle();

  if (error) throw new Error(`Verification check failed: ${error.message}`);
  if (!data) return true; // No row = legacy account, let them through
  return !!data.verified_at;
}

async function verifyToken(token) {
  const { data, error } = await supabase
    .from("email_verifications")
    .select("*")
    .eq("token", token)
    .maybeSingle();

  if (error) throw new Error("Verification lookup failed.");
  if (!data) return { success: false, message: "Invalid or expired verification link." };
  if (data.verified_at) return { success: true, alreadyVerified: true };
  if (new Date(data.expires_at) < new Date()) {
    return { success: false, message: "This link has expired. Please request a new one from the app." };
  }

  const { error: updateError } = await supabase
    .from("email_verifications")
    .update({ verified_at: new Date().toISOString() })
    .eq("user_id", data.user_id);

  if (updateError) throw new Error("Failed to mark email as verified.");
  return { success: true };
}

module.exports = {
  createVerificationToken,
  isVerified,
  verifyToken,
};
