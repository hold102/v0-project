const seedUsers = [
  { id: "u1", name: "Me", avatar: "👤" },
];

const seedGroups = [];

function createInitialDb() {
  return {
    currentUserId: seedUsers[0].id,
    accounts: [],
    users: structuredClone(seedUsers),
    groups: structuredClone(seedGroups),
  };
}

module.exports = {
  seedUsers,
  seedGroups,
  createInitialDb,
};
