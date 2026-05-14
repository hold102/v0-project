const { createId } = require("./idService");
const { readDb, updateDb } = require("./dbService");
const { RequestError } = require("../models/requestError");

function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

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
    const duplicate = db.users.find((user) => {
      const sameName = user.name.toLocaleLowerCase() === name.toLocaleLowerCase();
      const sameEmail = email && user.email && user.email.toLocaleLowerCase() === email.toLocaleLowerCase();
      return sameName || sameEmail;
    });

    if (duplicate) {
      return duplicate;
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

module.exports = {
  createOrReuseUser,
  getUserById,
  listUsers,
};
