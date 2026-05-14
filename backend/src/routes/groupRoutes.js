const express = require("express");
const {
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
  updateExpense,
} = require("../controllers/expenseController");

const router = express.Router();

router.get("/", listGroups);
router.get("/:groupId/balances", getBalances);
router.get("/:groupId/expenses", listExpenses);
router.post("/:groupId/expenses", createExpense);
router.put("/:groupId/expenses/:expenseId", updateExpense);
router.patch("/:groupId/expenses/:expenseId", updateExpense);
router.delete("/:groupId/expenses/:expenseId", deleteExpense);
router.get("/:id", getGroupById);
router.post("/", createGroup);
router.put("/:id", updateGroup);
router.patch("/:id", updateGroup);
router.delete("/:id", deleteGroup);

module.exports = router;
