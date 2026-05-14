/*
 * activity_screen.dart — Chronological feed of all expenses
 * Shows stats (total records, total amount) at the top, then a list
 * of every expense across all groups, grouped by date.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';

class ActivityScreen extends StatelessWidget {
  final void Function(String groupId) onGroupSelect;
  const ActivityScreen({super.key, required this.onGroupSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        // Collect all expenses
        final all = <Map<String, dynamic>>[];
        for (final g in app.groups) {
          for (final e in g.expenses.where((e) => e.category != ExpenseCategory.settlement)) {
            all.add({
              'expense': e,
              'groupName': g.name,
              'groupEmoji': g.emoji,
              'groupId': g.id,
            });
          }
        }
        all.sort((a, b) {
          final aDate = (a['expense'] as Expense).date;
          final bDate = (b['expense'] as Expense).date;
          return bDate.compareTo(aDate);
        });

        final totalAmount = all.fold<double>(
            0, (sum, item) => sum + (item['expense'] as Expense).amount);

        // Group by date
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final item in all) {
          final date = (item['expense'] as Expense).date;
          grouped.putIfAbsent(date, () => []).add(item);
        }

        return Column(
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Activity',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('View all expense records',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 10),
                          Text('${all.length}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Total records',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.trending_up_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 10),
                          Text('RM ${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Total Amount',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📝', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          const Text('No expense records yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Start adding expenses to track splits',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              child: Text(_formatDateHeader(entry.key),
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                            ...entry.value.map((item) {
                              final expense = item['expense'] as Expense;
                              final groupName = item['groupName'] as String;
                              final groupEmoji = item['groupEmoji'] as String;
                              final groupId = item['groupId'] as String;
                              final payer = app.getUserById(expense.paidBy);
                              final config =
                                  CategoryConfig.fromCategory(expense.category);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 3),
                                child: Card(
                                  child: InkWell(
                                    onTap: () => onGroupSelect(groupId),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: config.color,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(config.emoji,
                                                style: const TextStyle(
                                                    fontSize: 22)),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(expense.description,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15),
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${payer?.name ?? '?'} paid · $groupEmoji $groupName',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                  'RM ${expense.amount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                              Text(
                                                  '${expense.splitBetween.length} people splitting',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

String _formatDateHeader(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  final now = DateTime.now();
  final diff = now.difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '${diff}d ago';
  return '${date.year}/${date.month}/${date.day}';
}
