/*
 * userController.js — User CRUD handlers
 * Delegates to userService. "createOrReuseUser" means creating a user who
 * already exists (same name/email) will return the existing record instead
 * of creating a duplicate.
 */
const {
  createOrReuseUser,
  getUserById: getUserByIdService,
  listUsers: listUsersService,
} = require("../services/userService");

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

module.exports = {
  createUser,
  getUserById,
  listUsers,
};
