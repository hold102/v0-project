/*
 * authService.js — Registration and login logic
 *
 * Passwords are hashed with scrypt (key derivation) using a random salt,
 * and verified with timingSafeEqual to prevent timing attacks.
 *
 * Registration flow:
 *   1. Validate & normalize inputs
 *   2. If an account exists for the email → 409 Conflict
 *   3. If a user with the same email exists → reuse it; otherwise create a new user
 *   4. Hash the password, store the account, and set as current user
 *
 * Login flow:
 *   1. Find the account by email
 *   2. Compare the password hash with timingSafeEqual
 *   3. Set currentUserId so subsequent requests are authenticated
 */

const crypto = require("crypto");
const { createId, todayIsoDate } = require("./idService");
const { updateDb } = require("./supabaseService");
const { RequestError } = require("../models/requestError");
const { normalizeEmail, normalizeText } = require("../utils/normalize");
const { publicUser } = require("./userService");
const { createVerificationToken, isVerified } = require("./verificationService");
const { sendVerificationEmail } = require("./emailService");

function validateEmail(email) {
  if (!email || !email.includes("@") || email.startsWith("@") || email.endsWith("@")) {
    throw new RequestError("A valid email is required.");
  }
}

function validatePassword(password) {
  if (typeof password !== "string" || password.length < 6) {
    throw new RequestError("Password must be at least 6 characters.");
  }
}

// Derive a 64-byte hash from password + salt using scrypt
function hashPassword(password, salt) {
  return crypto.scryptSync(password, salt, 64).toString("hex");
}

// Constant-time comparison to prevent attackers from measuring response time
function verifyPassword(password, account) {
  const expected = Buffer.from(account.passwordHash, "hex");
  const actual = Buffer.from(hashPassword(password, account.salt), "hex");
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
}

async function register(body) {
  console.log("[authService] register called with email:", body?.email);
  const name = normalizeText(body?.name);
  const email = normalizeEmail(body?.email);
  const avatar = normalizeText(body?.avatar) || "👤";
  const password = body?.password;

  if (!name) {
    throw new RequestError("Name is required.");
  }
  validateEmail(email);
  validatePassword(password);

  const result = await updateDb((db) => {
    db.accounts = db.accounts || [];

    // Prevent duplicate accounts
    const existingAccount = db.accounts.find((account) => account.email === email);
    if (existingAccount) {
      throw new RequestError("An account already exists for this email.", 409);
    }

    // If a user with this email already exists (e.g., added as a group member),
    // reuse it instead of creating a duplicate
    let user = db.users.find((candidate) => {
      return candidate.email && candidate.email.toLocaleLowerCase() === email;
    });

    if (!user) {
      user = {
        id: createId("u"),
        name,
        avatar,
        email,
        currency: 'MYR',
      };
      db.users.push(user);
    } else {
      // Fill in any missing fields on the existing user
      user.name = user.name || name;
      user.avatar = user.avatar || avatar;
      user.email = user.email || email;
    }

    // Generate a random salt and hash the password
    const salt = crypto.randomBytes(16).toString("hex");
    db.accounts.push({
      userId: user.id,
      email,
      passwordHash: hashPassword(password, salt),
      salt,
      createdAt: todayIsoDate(),
    });
    // Don't auto-login — user must verify email first
    return { user: publicUser(user), userId: user.id };
  });

  // Send verification email outside updateDb (async external call)
  console.log("[authService] updateDb done, sending verification email to:", result?.userId);
  let token;
  try {
    token = await createVerificationToken(result.userId);
    await sendVerificationEmail(result.user.email, result.user.name, token);
  } catch (emailErr) {
    console.error("[authService] Failed to send verification email:", emailErr.message);
  }

  return { user: result.user, requiresVerification: true };
}

async function login(body) {
  const email = normalizeEmail(body?.email);
  const password = body?.password;

  validateEmail(email);
  if (typeof password !== "string" || password === "") {
    throw new RequestError("Password is required.");
  }

  return updateDb(async (db) => {
    db.accounts = db.accounts || [];
    const account = db.accounts.find((candidate) => candidate.email === email);

    if (!account || !verifyPassword(password, account)) {
      throw new RequestError("Invalid email or password.", 401);
    }

    const user = db.users.find((candidate) => candidate.id === account.userId);
    if (!user) {
      throw new RequestError("Account user was not found.", 404);
    }

    // Block login until email is verified
    const verified = await isVerified(account.userId);
    if (!verified) {
      throw new RequestError("Email not verified. Please check your inbox.", 403, "EMAIL_NOT_VERIFIED");
    }

    db.currentUserId = user.id;
    return { user: publicUser(user) };
  });
}

async function resendVerification(body) {
  const email = normalizeEmail(body?.email);
  validateEmail(email);

  // Read the DB without mutation to find the user
  const { readDb } = require("./supabaseService");
  const db = await readDb();
  const account = (db.accounts || []).find((a) => a.email === email);
  if (!account) {
    // Return success even if email not found to avoid leaking account existence
    return;
  }

  const verified = await isVerified(account.userId);
  if (verified) return; // Already verified, no need to resend

  const user = db.users.find((u) => u.id === account.userId);
  const token = await createVerificationToken(account.userId);
  await sendVerificationEmail(email, user?.name || "there", token);
}

module.exports = {
  login,
  register,
  resendVerification,
};
