const { test } = require("node:test");
const assert = require("node:assert/strict");
const { validateDb, clone } = require("../src/services/dbValidator");

function validDb() {
  return {
    currentUserId: "u1",
    users: [
      { id: "u1", name: "Me", avatar: "👤" },
      { id: "u2", name: "Alex", avatar: "😎" },
    ],
    accounts: [],
    groups: [
      {
        id: "g1",
        name: "Trip",
        emoji: "✈️",
        members: [
          { id: "u1", name: "Me", avatar: "👤" },
          { id: "u2", name: "Alex", avatar: "😎" },
        ],
        expenses: [
          {
            id: "e1",
            description: "Taxi",
            amount: 30,
            paidBy: "u1",
            splitBetween: ["u1", "u2"],
            category: "transport",
            date: "2026-05-14",
            groupId: "g1",
          },
        ],
        settlements: [],
        createdAt: "2026-05-01",
      },
    ],
  };
}

test("validateDb accepts a well-formed db", () => {
  assert.doesNotThrow(() => validateDb(validDb()));
});

test("validateDb rejects unknown currentUserId", () => {
  const db = validDb();
  db.currentUserId = "ghost";
  assert.throws(() => validateDb(db), /Current user does not exist/);
});

test("validateDb rejects expense with non-member payer", () => {
  const db = validDb();
  db.groups[0].expenses[0].paidBy = "u-outside";
  assert.throws(() => validateDb(db), /payer is not a group member/);
});

test("validateDb rejects negative expense amount", () => {
  const db = validDb();
  db.groups[0].expenses[0].amount = -5;
  assert.throws(() => validateDb(db), /amount must be positive/);
});

test("validateDb rejects invalid category", () => {
  const db = validDb();
  db.groups[0].expenses[0].category = "bogus";
  assert.throws(() => validateDb(db), /category is invalid/);
});

test("validateDb rejects expense.groupId mismatching its parent group", () => {
  const db = validDb();
  db.groups[0].expenses[0].groupId = "g-other";
  assert.throws(() => validateDb(db), /group id does not match/);
});

test("clone produces a deep copy", () => {
  const db = validDb();
  const copy = clone(db);
  copy.groups[0].expenses[0].amount = 999;
  assert.equal(db.groups[0].expenses[0].amount, 30);
});
