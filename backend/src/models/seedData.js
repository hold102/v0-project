/*
 * seedData.js — Initial database state for first-time setup
 * When the JSON database file doesn't exist yet, createInitialDb() produces
 * a fresh database with one default "Me" user and no groups.
 */
const seedUsers = [
  { id: "u1", name: "Me", avatar: "👤" },
];

const seedGroups = [];

function createInitialDb() {
  return {
    currentUserId: seedUsers[0].id,  // Log in as the seed user by default
    accounts: [],
    users: structuredClone(seedUsers),  // structuredClone so the original can't be mutated
    groups: structuredClone(seedGroups),
  };
}

module.exports = {
  seedUsers,
  seedGroups,
  createInitialDb,
};
