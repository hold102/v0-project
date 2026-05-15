import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/widgets/glass_card.dart';
import 'package:splitease/theme/app_theme.dart';

class GroupsScreen extends StatelessWidget {
  final void Function(String groupId) onGroupSelect;
  const GroupsScreen({super.key, required this.onGroupSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Groups',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: GlassColors.text)),
                  const SizedBox(height: 4),
                  const Text('Manage your expense groups',
                      style: TextStyle(
                          color: GlassColors.textMuted, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: app.groups.isEmpty
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
                              child: const Icon(Icons.group_rounded,
                                  size: 40,
                                  color: GlassColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            const Text('No groups yet',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: GlassColors.text)),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap the + button below to create your first group',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: GlassColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: app.groups.length,
                      itemBuilder: (context, index) {
                        final group = app.groups[index];
                        return Dismissible(
                          key: ValueKey('group-${group.id}'),
                          direction: DismissDirection.endToStart,
                          background: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 4),
                            child: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: GlassColors.negative
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: GlassColors.negative
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      color: GlassColors.negative),
                                  SizedBox(width: 6),
                                  Text('Delete',
                                      style: TextStyle(
                                          color: GlassColors.negative,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          confirmDismiss: (_) =>
                              _confirmDeleteGroup(context, group),
                          onDismissed: (_) =>
                              context.read<AppProvider>().deleteGroup(group.id),
                          child: _GroupListTile(
                            group: group,
                            onTap: () => onGroupSelect(group.id),
                            onLongPress: () async {
                              final ok =
                                  await _confirmDeleteGroup(context, group);
                              if (ok == true && context.mounted) {
                                context
                                    .read<AppProvider>()
                                    .deleteGroup(group.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

Future<bool?> _confirmDeleteGroup(BuildContext context, Group group) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1535),
      title: Text('Delete "${group.name}"?',
          style: const TextStyle(color: GlassColors.text)),
      content: const Text(
        'This removes the group and all of its expenses. This cannot be undone.',
        style: TextStyle(color: GlassColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel',
              style: TextStyle(color: GlassColors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete',
              style: TextStyle(
                  color: GlassColors.negative, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _GroupListTile extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _GroupListTile({
    required this.group,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final balances = app.calculateBalances(group);
    final myBalance = balances.fold<double>(0, (acc, b) {
      if (b.to == app.currentUser.id) return acc + b.amount;
      if (b.from == app.currentUser.id) return acc - b.amount;
      return acc;
    });

    final balanceColor = myBalance > 0.01
        ? GlassColors.positive
        : myBalance < -0.01
            ? GlassColors.negative
            : GlassColors.textMuted;
    final balanceText = myBalance > 0.01
        ? '+RM ${myBalance.toStringAsFixed(2)}'
        : myBalance < -0.01
            ? '-RM ${myBalance.abs().toStringAsFixed(2)}'
            : 'Settled';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: GlassTile(
        borderRadius: 18,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(group.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: GlassColors.text)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.group,
                          size: 13, color: GlassColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${group.members.length} members',
                          style: const TextStyle(
                              color: GlassColors.textMuted, fontSize: 12)),
                      const Text(' · ',
                          style: TextStyle(color: GlassColors.textMuted)),
                      Text('${group.expenses.length} expenses',
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
                Text(balanceText,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: balanceColor)),
                const SizedBox(height: 2),
                Text(
                    'Total RM ${group.totalExpenses.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: GlassColors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: GlassColors.textMuted, size: 22),
          ],
        ),
      ),
      ),
    );
  }
}
