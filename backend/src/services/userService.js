/*
 * userService.js — User management logic
 *
 * "createOrReuseUser" is designed for adding members to groups: if a user
 * with the same name or email already exists, it returns the existing record
 * instead of creating a duplicate. This prevents proliferation of near-duplicate
 * users in the member list.
 */

const { createId } = require("./idService");
const { readDb, updateDb } = require("./supabaseService");
const { RequestError } = require("../models/requestError");
const { normalizeText } = require("../utils/normalize");

async function createOrReuseUser(body) {
  if (!body || typeof body.name !== "string" || !body.name.trim()) {
    throw new RequestError("Member name is required.");
  }

  if (body.email !== undefined && typeof body.email !== "string") {
    throw new RequestError("Member email must be text.");
  }

  if (body.avatar !== undefined && typeof body.avatar !== "string") {
    throw new RequestError("Member avatar must be text.");
  }

  const name = body.name.trim();
  const email = normalizeText(body.email) || undefined;
  const avatar = normalizeText(body.avatar) || "👤";

  return updateDb((db) => {
    // Case-insensitive match on name or email to detect duplicates
    const duplicate = db.users.find((user) => {
      const sameName = user.name.toLocaleLowerCase() === name.toLocaleLowerCase();
      const sameEmail = email && user.email && user.email.toLocaleLowerCase() === email.toLocaleLowerCase();
      return sameName || sameEmail;
    });

    if (duplicate) {
      return duplicate;  // Reuse existing user
    }

    const user = {
      id: createId("u"),
      name,
      avatar,
      email,
    };

    db.users.push(user);
    return user;
  });
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    avatar: user.avatar,
    email: user.email,
  };
}

async function listUsers() {
  const db = await readDb();
  return db.users.map(publicUser);
}

async function getUserById(id) {
  if (typeof id !== "string" || !id.trim()) {
    throw new RequestError("User id is required.");
  }

  const db = await readDb();
  const user = db.users.find((candidate) => candidate.id === id);
  if (!user) {
    throw new RequestError("User not found.", 404);
  }

  return publicUser(user);
}

async function getUserByEmail(email) {
  if (typeof email !== "string" || !email.trim()) {
    throw new RequestError("Email is required.");
  }

  const db = await readDb();
  const user = db.users.find(
    (u) => u.email && u.email.toLocaleLowerCase() === email.trim().toLocaleLowerCase()
  );
  if (!user) {
    throw new RequestError("No user found with that email.", 404);
  }

  return publicUser(user);
}

module.exports = {
  createOrReuseUser,
  getUserById,
  getUserByEmail,
  listUsers,
  publicUser,
};
