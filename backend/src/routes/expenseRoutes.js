const express = require("express");
const { createExpense, deleteExpense, updateExpense } = require("../controllers/expenseController");

const router = express.Router();

router.post("/", createExpense);
router.put("/", updateExpense);
router.patch("/", updateExpense);
router.delete("/", deleteExpense);

module.exports = router;
