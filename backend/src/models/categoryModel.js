const expenseCategories = [
  "food",
  "transport",
  "entertainment",
  "shopping",
  "accommodation",
  "utilities",
  "other",
];

const categoryConfig = {
  food: { label: "Food", emoji: "🍜" },
  transport: { label: "Transport", emoji: "🚗" },
  entertainment: { label: "Entertainment", emoji: "🎬" },
  shopping: { label: "Shopping", emoji: "🛍️" },
  accommodation: { label: "Accommodation", emoji: "🏨" },
  utilities: { label: "Utilities", emoji: "💡" },
  other: { label: "Other", emoji: "📦" },
};

function isExpenseCategory(value) {
  return typeof value === "string" && expenseCategories.includes(value);
}

module.exports = {
  categoryConfig,
  expenseCategories,
  isExpenseCategory,
};
