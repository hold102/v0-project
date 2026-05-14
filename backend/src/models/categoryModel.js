/*
 * categoryModel.js — Expense category definitions
 * Maps each category key (e.g. "food") to a human-readable label and emoji
 * for display in the UI. Also exports a validation helper.
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

// Each category's display-friendly metadata
const categoryConfig = {
  food: { label: "Food", emoji: "🍜" },
  transport: { label: "Transport", emoji: "🚗" },
  entertainment: { label: "Entertainment", emoji: "🎬" },
  shopping: { label: "Shopping", emoji: "🛍️" },
  accommodation: { label: "Accommodation", emoji: "🏨" },
  utilities: { label: "Utilities", emoji: "💡" },
  other: { label: "Other", emoji: "📦" },
  settlement: { label: "Settlement", emoji: "💰" },
};

function isExpenseCategory(value) {
  return typeof value === "string" && expenseCategories.includes(value);
}

module.exports = {
  categoryConfig,
  expenseCategories,
  isExpenseCategory,
};
