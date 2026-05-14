const { test } = require("node:test");
const assert = require("node:assert/strict");
const { createId, todayIsoDate } = require("../src/services/idService");

test("createId prefixes the id", () => {
  const id = createId("u");
  assert.ok(id.startsWith("u"), `expected prefix "u", got ${id}`);
});

test("createId returns unique ids for repeated calls", () => {
  const ids = new Set();
  for (let i = 0; i < 1000; i++) ids.add(createId("x"));
  assert.equal(ids.size, 1000);
});

test("todayIsoDate returns YYYY-MM-DD", () => {
  assert.match(todayIsoDate(), /^\d{4}-\d{2}-\d{2}$/);
});
