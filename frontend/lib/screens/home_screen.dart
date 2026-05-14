/*
 * home_screen.dart — Main dashboard
 * Shows a net balance card (with gradient), a horizontal group carousel,
 * and a recent-activity list (last 5 expenses).
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/widgets/group_card.dart';
import 'package:splitease/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final void Function(String groupId) onGroupSelect;
  const HomeScreen({super.key, required this.onGroupSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalOwed = app.getTotalOwed();
        final totalOwing = app.getTotalOwing();
        final recent = app.getRecentActivity();

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(app.currentUser.name,
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(app.currentUser.avatar,
                                      style: const TextStyle(fontSize: 22)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.trending_up_rounded,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Balance Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded,
                                          color: Colors.greenAccent, size: 20),
                                      const SizedBox(width: 6),
                                      Text('Owed to you',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'RM ${totalOwed.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded,
                                          color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 6),
                                      Text('You owe',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'RM ${totalOwing.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Groups section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Groups',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('${app.groups.length} groups',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 166,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: app.groups.length,
                      itemBuilder: (context, index) {
                        final group = app.groups[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GroupCard(
                            group: group,
                            onTap: () => onGroupSelect(group.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Recent activity
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Recent Activity',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                          child: Text('No activity yet',
                              style: TextStyle(color: Colors.grey))),
                    ),
                  for (final item in recent)
                    _RecentExpenseTile(
                      expense: item['expense'] as Expense,
                      groupName: item['groupName'] as String,
                      groupEmoji: item['groupEmoji'] as String,
                      onTap: () => onGroupSelect(item['groupId'] as String),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  final Expense expense;
  final String groupName;
  final String groupEmoji;
  final VoidCallback onTap;

  const _RecentExpenseTile({
    required this.expense,
    required this.groupName,
    required this.groupEmoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final payer = app.getUserById(expense.paidBy);
    final config = CategoryConfig.fromCategory(expense.category);
    final me = app.currentUser.id;
    final iPaid = expense.paidBy == me;
    final iSplit = expense.splitBetween.contains(me);
    final myShare = iSplit ? expense.shareFor(me) : 0.0;

    // Label + colour for my involvement
    final String roleLabel;
    final Color roleColor;
    if (iPaid && iSplit) {
      final lent = expense.amount - myShare;
      roleLabel = lent > 0.01 ? 'You lent RM ${lent.toStringAsFixed(2)}' : 'You paid';
      roleColor = AppColors.positiveBalance;
    } else if (iPaid) {
      roleLabel = 'You paid RM ${expense.amount.toStringAsFixed(2)}';
      roleColor = AppColors.positiveBalance;
    } else if (iSplit) {
      roleLabel = 'You owe RM ${myShare.toStringAsFixed(2)}';
      roleColor = AppColors.negativeBalance;
    } else {
      roleLabel = 'Not involved';
      roleColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: config.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(config.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(groupEmoji,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(groupName,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('RM ${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(_formatDate(expense.date),
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${payer?.avatar ?? '👤'} ${payer?.name ?? '?'} paid',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    Text(
                        ' · ${expense.splitBetween.length} people',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(roleLabel,
                          style: TextStyle(
                              color: roleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return '${date.month}/${date.day}';
  }
}
