/*
 * group.dart — A group of users splitting expenses together
 * Each group has members, a list of expenses, and a creation date.
 * totalExpenses sums all expense amounts.
 */
import 'package:splitease/models/user.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';

class Group {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<User> members;
  final List<Expense> expenses;
  final String createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.emoji,
    this.description = '',
    required this.members,
    required this.expenses,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      description: (json['description'] as String?) ?? '',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'members': members.map((m) => m.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
      };

  // Sum of all non-settlement expenses in this group
  double get totalExpenses => expenses
      .where((e) => e.category != ExpenseCategory.settlement)
      .fold(0, (sum, e) => sum + e.amount);

  // Parse the ISO date string, falling back to now if parsing fails
  DateTime get createdDate => DateTime.tryParse(createdAt) ?? DateTime.now();
}
