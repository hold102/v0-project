import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  entertainment,
  shopping,
  accommodation,
  utilities,
  other,
}

class CategoryConfig {
  final ExpenseCategory category;
  final String label;
  final String emoji;
  final Color color;

  const CategoryConfig({
    required this.category,
    required this.label,
    required this.emoji,
    required this.color,
  });

  static const Map<ExpenseCategory, CategoryConfig> configs = {
    ExpenseCategory.food: CategoryConfig(
      category: ExpenseCategory.food,
      label: 'Food',
      emoji: '🍜',
      color: Color(0xFFFEF3C7),
    ),
    ExpenseCategory.transport: CategoryConfig(
      category: ExpenseCategory.transport,
      label: 'Transport',
      emoji: '🚗',
      color: Color(0xFFE0F2FE),
    ),
    ExpenseCategory.entertainment: CategoryConfig(
      category: ExpenseCategory.entertainment,
      label: 'Entertainment',
      emoji: '🎬',
      color: Color(0xFFFFE4E6),
    ),
    ExpenseCategory.shopping: CategoryConfig(
      category: ExpenseCategory.shopping,
      label: 'Shopping',
      emoji: '🛍️',
      color: Color(0xFFEDE9FE),
    ),
    ExpenseCategory.accommodation: CategoryConfig(
      category: ExpenseCategory.accommodation,
      label: 'Accommodation',
      emoji: '🏨',
      color: Color(0xFFD1FAE5),
    ),
    ExpenseCategory.utilities: CategoryConfig(
      category: ExpenseCategory.utilities,
      label: 'Utilities',
      emoji: '💡',
      color: Color(0xFFFEF9C3),
    ),
    ExpenseCategory.other: CategoryConfig(
      category: ExpenseCategory.other,
      label: 'Other',
      emoji: '📦',
      color: Color(0xFFF1F5F9),
    ),
  };

  static CategoryConfig fromCategory(ExpenseCategory cat) => configs[cat]!;

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}
