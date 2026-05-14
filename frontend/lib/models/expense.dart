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
      paidBy: json['paidBy'] as String? ?? json['paid_by'] as String,
      splitBetween: (json['splitBetween'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
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
        'category': category.name,
        'date': date,
        'groupId': groupId,
      };

  double get perPerson =>
      splitBetween.isNotEmpty ? amount / splitBetween.length : amount;
}
