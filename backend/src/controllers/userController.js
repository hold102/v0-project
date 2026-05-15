/*
 * userController.js — User CRUD handlers
 * Delegates to userService. "createOrReuseUser" means creating a user who
 * already exists (same name/email) will return the existing record instead
 * of creating a duplicate.
 */
const {
  createOrReuseUser,
  getUserById: getUserByIdService,
  getUserByEmail: getUserByEmailService,
  searchUsers: searchUsersService,
  listUsers: listUsersService,
  updateUserCurrency,
} = require("../services/userService");
const { readDb } = require("../services/supabaseService");
const { RequestError } = require("../models/requestError");

async function listUsers(_req, res, next) {
  try {
    const users = await listUsersService();
    res.json(users);
  } catch (error) {
    next(error);
  }
}

async function getUserById(req, res, next) {
  try {
    const user = await getUserByIdService(req.params.id);
    res.json(user);
  } catch (error) {
    next(error);
  }
}

async function createUser(req, res, next) {
  try {
    const user = await createOrReuseUser(req.body);
    res.status(201).json(user);
  } catch (error) {
    next(error);
  }
}

async function lookupByEmail(req, res, next) {
  try {
    const user = await getUserByEmailService(req.query.email);
    res.json(user);
  } catch (error) {
    next(error);
  }
}

async function searchUsers(req, res, next) {
  try {
    const users = await searchUsersService(req.query.q || "");
    res.json(users);
  } catch (error) {
    next(error);
  }
}

async function setMyCurrency(req, res, next) {
  try {
    const db = await readDb();
    if (!db.currentUserId) throw new RequestError('Not signed in.', 401);
    const updated = await updateUserCurrency(db.currentUserId, req.body?.currency);
    res.json(updated);
  } catch (e) {
    next(e);
  }
}

module.exports = {
  createUser,
  getUserById,
  listUsers,
  lookupByEmail,
  searchUsers,
  setMyCurrency,
};
