const { readDb } = require("../services/dbService");

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
