/*
 * expense.dart — An expense record within a group
 * Stores what was spent, who paid, who it's split between, and a category.
 * The `perPerson` getter computes how much each split member owes.
 */
import 'package:splitease/models/expense_category.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final List<String> splitBetween;
  final ExpenseCategory category;
  final String date;
  final String groupId;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    required this.category,
    required this.date,
    required this.groupId,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] as String? ?? json['paid_by'] as String,  // Supports both camelCase and snake_case
      splitBetween: (json['splitBetween'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category:
          CategoryConfig.fromString(json['category'] as String? ?? 'other'),  // Default to "other" if missing
      date: json['date'] as String,
      groupId: json['groupId'] as String? ?? json['group_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'paidBy': paidBy,
        'splitBetween': splitBetween,
        'category': category.name,
        'date': date,
        'groupId': groupId,
      };

  // How much each person pays for this expense (total / number of splitters)
  double get perPerson =>
      splitBetween.isNotEmpty ? amount / splitBetween.length : amount;
}
