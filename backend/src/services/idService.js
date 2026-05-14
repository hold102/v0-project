function createId(prefix) {
  return `${prefix}${Date.now()}${Math.random().toString(36).slice(2, 8)}`;
}

function todayIsoDate() {
  return new Date().toISOString().split("T")[0];
}

module.exports = {
  createId,
  todayIsoDate,
};
