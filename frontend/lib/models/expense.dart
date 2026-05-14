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
  // Optional: explicit dollar share per user id. null = equal split.
  // When non-null, must contain every user in splitBetween and sum to amount.
  final Map<String, double>? splitAmounts;
  final ExpenseCategory category;
  final String date;
  final String groupId;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    this.splitAmounts,
    required this.category,
    required this.date,
    required this.groupId,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final rawAmounts = json['splitAmounts'];
    Map<String, double>? amounts;
    if (rawAmounts is Map) {
      amounts = {};
      rawAmounts.forEach((k, v) {
        if (k is String && v is num) amounts![k] = v.toDouble();
      });
      if (amounts.isEmpty) amounts = null;
    }
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] as String? ?? json['paid_by'] as String,
      splitBetween: (json['splitBetween'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      splitAmounts: amounts,
      category:
          CategoryConfig.fromString(json['category'] as String? ?? 'other'),
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
        if (splitAmounts != null) 'splitAmounts': splitAmounts,
        'category': category.name,
        'date': date,
        'groupId': groupId,
      };

  // Per-user share of this expense.
  // Uses explicit splitAmounts when present; otherwise an equal split.
  double shareFor(String userId) {
    final custom = splitAmounts?[userId];
    if (custom != null) return custom;
    return splitBetween.isNotEmpty ? amount / splitBetween.length : amount;
  }

  // Default per-person share (equal-split fallback) — kept for backwards-compat callers.
  double get perPerson =>
      splitBetween.isNotEmpty ? amount / splitBetween.length : amount;
}
