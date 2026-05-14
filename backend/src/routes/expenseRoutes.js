/*
 * expenseRoutes.js — Expense routes (standalone, without group prefix)
 * These mount under /api/expenses.
 * The same controllers are also mounted under /api/groups/:groupId/expenses in groupRoutes.js.
 */
const express = require("express");
const { createExpense, deleteExpense, updateExpense } = require("../controllers/expenseController");

const router = express.Router();

// POST /api/expenses — create an expense (groupId comes from the request body)
router.post("/", createExpense);
// PUT & PATCH — update an expense (expenseId comes from the request body)
router.put("/", updateExpense);
router.patch("/", updateExpense);
// DELETE — remove an expense (groupId & expenseId from request body)
router.delete("/", deleteExpense);

module.exports = router;
