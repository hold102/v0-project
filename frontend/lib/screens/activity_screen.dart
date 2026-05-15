import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/widgets/glass_card.dart';
import 'package:splitease/theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  final void Function(String groupId) onGroupSelect;
  const ActivityScreen({super.key, required this.onGroupSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final all = <Map<String, dynamic>>[];
        for (final g in app.groups) {
          for (final e in g.expenses
              .where((e) => e.category != ExpenseCategory.settlement)) {
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

        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final item in all) {
          final date = (item['expense'] as Expense).date;
          grouped.putIfAbsent(date, () => []).add(item);
        }

        return Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Activity',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: GlassColors.text)),
                  const SizedBox(height: 4),
                  const Text('View all expense records',
                      style: TextStyle(
                          color: GlassColors.textMuted, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GlassTile(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.schedule_rounded,
                                size: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text('${all.length}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: GlassColors.text)),
                          const SizedBox(height: 2),
                          const Text('Total records',
                              style: TextStyle(
                                  color: GlassColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassTile(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.trending_up_rounded,
                                size: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text('RM ${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: GlassColors.text)),
                          const SizedBox(height: 2),
                          const Text('Total amount',
                              style: TextStyle(
                                  color: GlassColors.textMuted, fontSize: 12)),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: GlassColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border:
                                    Border.all(color: GlassColors.border),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.article_outlined,
                                  size: 40, color: GlassColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            const Text('No expense records yet',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: GlassColors.text)),
                            const SizedBox(height: 8),
                            const Text(
                              'Start adding expenses to track splits',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: GlassColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
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
                                  horizontal: 24, vertical: 8),
                              child: Text(
                                _formatDateHeader(entry.key),
                                style: const TextStyle(
                                    color: GlassColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            ...entry.value.map((item) {
                              final expense = item['expense'] as Expense;
                              final groupName = item['groupName'] as String;
                              final groupEmoji = item['groupEmoji'] as String;
                              final groupId = item['groupId'] as String;
                              final payer =
                                  app.getUserById(expense.paidBy);
                              final config = CategoryConfig.fromCategory(
                                  expense.category);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 4),
                                child: GlassTile(
                                  borderRadius: 18,
                                  onTap: () => onGroupSelect(groupId),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: config.color
                                              .withValues(alpha: 0.9),
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
                                                    fontSize: 15,
                                                    color: GlassColors.text),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${payer == null ? '?' : app.displayName(payer)} paid · $groupEmoji $groupName',
                                              style: const TextStyle(
                                                  color:
                                                      GlassColors.textMuted,
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
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: GlassColors.text),
                                          ),
                                          Text(
                                            '${expense.splitBetween.length} people',
                                            style: const TextStyle(
                                                color: GlassColors.textMuted,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
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
  final diff = DateTime.now().difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '${diff}d ago';
  return '${date.year}/${date.month}/${date.day}';
}
