const crypto = require("crypto");
const { createId, todayIsoDate } = require("./idService");
const { updateDb } = require("./dbService");
const { RequestError } = require("../models/requestError");

function normalizeEmail(value) {
  return typeof value === "string" ? value.trim().toLocaleLowerCase() : "";
}

function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

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

function hashPassword(password, salt) {
  return crypto.scryptSync(password, salt, 64).toString("hex");
}

function verifyPassword(password, account) {
  const expected = Buffer.from(account.passwordHash, "hex");
  const actual = Buffer.from(hashPassword(password, account.salt), "hex");
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    avatar: user.avatar,
    email: user.email,
  };
}

async function register(body) {
  const name = normalizeText(body?.name);
  const email = normalizeEmail(body?.email);
  const avatar = normalizeText(body?.avatar) || "👤";
  const password = body?.password;

  if (!name) {
    throw new RequestError("Name is required.");
  }
  validateEmail(email);
  validatePassword(password);

  return updateDb((db) => {
    db.accounts = db.accounts || [];

    const existingAccount = db.accounts.find((account) => account.email === email);
    if (existingAccount) {
      throw new RequestError("An account already exists for this email.", 409);
    }

    let user = db.users.find((candidate) => {
      return candidate.email && candidate.email.toLocaleLowerCase() === email;
    });

    if (!user) {
      user = {
        id: createId("u"),
        name,
        avatar,
        email,
      };
      db.users.push(user);
    } else {
      user.name = user.name || name;
      user.avatar = user.avatar || avatar;
      user.email = user.email || email;
    }

    const salt = crypto.randomBytes(16).toString("hex");
    db.accounts.push({
      userId: user.id,
      email,
      passwordHash: hashPassword(password, salt),
      salt,
      createdAt: todayIsoDate(),
    });
    db.currentUserId = user.id;

    return { user: publicUser(user) };
  });
}

async function login(body) {
  const email = normalizeEmail(body?.email);
  const password = body?.password;

  validateEmail(email);
  if (typeof password !== "string" || password === "") {
    throw new RequestError("Password is required.");
  }

  return updateDb((db) => {
    db.accounts = db.accounts || [];
    const account = db.accounts.find((candidate) => candidate.email === email);

    if (!account || !verifyPassword(password, account)) {
      throw new RequestError("Invalid email or password.", 401);
    }

    const user = db.users.find((candidate) => candidate.id === account.userId);
    if (!user) {
      throw new RequestError("Account user was not found.", 404);
    }

    db.currentUserId = user.id;
    return { user: publicUser(user) };
  });
}

module.exports = {
  login,
  register,
};
