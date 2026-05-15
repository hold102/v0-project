import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/widgets/group_card.dart';
import 'package:splitease/widgets/glass_card.dart';
import 'package:splitease/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final void Function(String groupId) onGroupSelect;
  const HomeScreen({super.key, required this.onGroupSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.loading) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final totalOwed = app.getTotalOwed();
        final totalOwing = app.getTotalOwing();
        // Total amount across all groups + the current user's own share.
        final myId = app.currentUser.id;
        final totalAmount = app.groups.fold<double>(
            0, (sum, g) => sum + g.totalExpenses);
        final mySpent = app.groups.fold<double>(0, (sum, g) {
          for (final e in g.expenses) {
            if (e.category.name == 'settlement') continue;
            if (e.splitBetween.contains(myId)) sum += e.shareFor(myId);
          }
          return sum;
        });
        final recent = app.getRecentActivity();

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back',
                            style: TextStyle(
                                color: GlassColors.textMuted, fontSize: 14)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(app.currentUser.name,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: GlassColors.text),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: GlassColors.surfaceHeavy,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GlassColors.border),
                        ),
                        child: const Icon(Icons.trending_up_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Top stats — active groups + my total spending (own share).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _HomeStatTile(
                      title: 'RM ${totalAmount.toStringAsFixed(0)}',
                      subtitle: 'Total amount',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeStatTile(
                      title: 'RM ${mySpent.toStringAsFixed(0)}',
                      subtitle: 'Your total spent',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Balance Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                color: const Color(0x33764BA2), // tinted purple glass
                child: Row(
                  children: [
                    Expanded(
                      child: _BalanceSubCard(
                        icon: Icons.arrow_downward_rounded,
                        iconColor: GlassColors.positive,
                        label: 'Owed to you',
                        amount: 'RM ${totalOwed.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceSubCard(
                        icon: Icons.arrow_upward_rounded,
                        iconColor: GlassColors.negative,
                        label: 'You owe',
                        amount: 'RM ${totalOwing.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Groups section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Groups',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: GlassColors.text)),
                  Text('${app.groups.length} groups',
                      style: const TextStyle(
                          color: GlassColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
            // Recent activity header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Recent Activity',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: GlassColors.text)),
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassTile(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Text('No activity yet',
                        style: TextStyle(color: GlassColors.textMuted)),
                  ),
                ),
              ),
            for (final item in recent)
              _RecentExpenseTile(
                expense: item['expense'] as Expense,
                groupName: item['groupName'] as String,
                groupEmoji: item['groupEmoji'] as String,
                onTap: () => onGroupSelect(item['groupId'] as String),
              ),
          ],
        );
      },
    );
  }
}

class _BalanceSubCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;

  const _BalanceSubCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: GlassColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
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

    final String roleLabel;
    final Color roleColor;
    if (iPaid && iSplit) {
      final lent = expense.amount - myShare;
      roleLabel =
          lent > 0.01 ? 'Lent RM ${lent.toStringAsFixed(2)}' : 'You paid';
      roleColor = GlassColors.positive;
    } else if (iPaid) {
      roleLabel = 'Paid RM ${expense.amount.toStringAsFixed(2)}';
      roleColor = GlassColors.positive;
    } else if (iSplit) {
      roleLabel = 'Owe RM ${myShare.toStringAsFixed(2)}';
      roleColor = GlassColors.negative;
    } else {
      roleLabel = 'Not involved';
      roleColor = GlassColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: GlassTile(
        borderRadius: 18,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(config.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.description,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: GlassColors.text),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(groupEmoji,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(groupName,
                              style: const TextStyle(
                                  color: GlassColors.textMuted, fontSize: 12)),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: GlassColors.text)),
                    Text(_formatDate(expense.date),
                        style: const TextStyle(
                            color: GlassColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(
                color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                    '${payer?.avatar ?? '👤'} ${payer == null ? '?' : app.displayName(payer)} paid · ${expense.splitBetween.length} people',
                    style: const TextStyle(
                        color: GlassColors.textMuted, fontSize: 12)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
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
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return '${date.month}/${date.day}';
  }
}

class _HomeStatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HomeStatTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: GlassColors.text)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: GlassColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
