const expenseCategories = [
  "food",
  "transport",
  "entertainment",
  "shopping",
  "accommodation",
  "utilities",
  "other",
];

const expenseCategorySet = new Set(expenseCategories);

function isExpenseCategory(value) {
  return typeof value === "string" && expenseCategorySet.has(value);
}

module.exports = {
  expenseCategories,
  isExpenseCategory,
};
