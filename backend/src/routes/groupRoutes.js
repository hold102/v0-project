/*
 * groupRoutes.js — Group and nested-expense routes
 * Mounted under /api/groups.
 *
 * Top-level group CRUD:
 *   GET    /              — list groups visible to current user
 *   POST   /              — create a new group
 *   GET    /:id           — get a single group by ID
 *   PUT    /:id           — update a group
 *   DELETE /:id           — delete a group
 *
 * Nested expense routes (groupId from URL):
 *   GET    /:groupId/expenses              — list expenses in a group
 *   POST   /:groupId/expenses              — add an expense to a group
 *   PUT    /:groupId/expenses/:expenseId   — update an expense
 *   DELETE /:groupId/expenses/:expenseId   — delete an expense
 *   GET    /:groupId/balances              — calculate who owes whom
 */
const express = require("express");
const {
  addMemberToGroup,
  createGroup,
  deleteGroup,
  getGroupById,
  listGroups,
  updateGroup,
} = require("../controllers/groupController");
const {
  createExpense,
  deleteExpense,
  getBalances,
  listExpenses,
  recordSettlement,
  updateExpense,
} = require("../controllers/expenseController");

const router = express.Router();

// Group routes
router.get("/", listGroups);
router.post("/", createGroup);
router.get("/:id", getGroupById);
router.put("/:id", updateGroup);
router.patch("/:id", updateGroup);
router.delete("/:id", deleteGroup);
router.post("/:id/members", addMemberToGroup);

// Nested expense + balance routes (groupId from URL path)
router.get("/:groupId/balances", getBalances);
router.post("/:groupId/settlements", recordSettlement);
router.get("/:groupId/expenses", listExpenses);
router.post("/:groupId/expenses", createExpense);
router.put("/:groupId/expenses/:expenseId", updateExpense);
router.patch("/:groupId/expenses/:expenseId", updateExpense);
router.delete("/:groupId/expenses/:expenseId", deleteExpense);

module.exports = router;
