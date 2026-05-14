/*
 * categories.js — Valid expense category keys (backend variant)
 * This is the validation-only module; categoryModel.js is the full version
 * that also carries display labels and emoji.
 */
const expenseCategories = [
  "food",
  "transport",
  "entertainment",
  "shopping",
  "accommodation",
  "utilities",
  "other",
  "settlement",
];

// Use a Set for O(1) lookups when validating
const expenseCategorySet = new Set(expenseCategories);

function isExpenseCategory(value) {
  return typeof value === "string" && expenseCategorySet.has(value);
}

module.exports = {
  expenseCategories,
  isExpenseCategory,
};
