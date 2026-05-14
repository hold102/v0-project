/*
 * idService.js — ID generation and date helpers
 * createId("u") → "u1716298123456x7k9q2m" (prefix + timestamp + random suffix)
 * todayIsoDate() → "2026-05-14"
 */
function createId(prefix) {
  // Timestamp ensures uniqueness across restarts; random suffix prevents collisions in the same ms
  return `${prefix}${Date.now()}${Math.random().toString(36).slice(2, 8)}`;
}

function todayIsoDate() {
  // ISO string looks like "2026-05-14T12:34:56.789Z" — split on "T" takes just the date part
  return new Date().toISOString().split("T")[0];
}

module.exports = {
  createId,
  todayIsoDate,
};
