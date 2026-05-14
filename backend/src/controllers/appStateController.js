/*
 * appStateController.js — Bootstraps the frontend with initial app state
 * GET / returns the current user ID, all known users, and only the groups
 * the current user belongs to. Called once when the app loads.
 */
const { readDb } = require("../services/supabaseService");

// Strip sensitive fields from a user object before sending to the frontend
function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    avatar: user.avatar,
    email: user.email,
  };
}

async function getAppState(_req, res, next) {
  try {
    const db = await readDb();
    res.json({
      currentUserId: db.currentUserId,
      users: db.users.map(publicUser),
      // Only return groups the current user is a member of
      groups: db.groups.filter((group) =>
        group.members.some((member) => member.id === db.currentUserId)
      ),
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAppState,
};
