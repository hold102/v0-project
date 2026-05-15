import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/theme/app_theme.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final balances = app.calculateBalances(group);
    final hasOutstanding = balances.isNotEmpty;
    final myBalance = balances.fold<double>(0, (acc, b) {
      if (b.to == app.currentUser.id) return acc + b.amount;
      if (b.from == app.currentUser.id) return acc - b.amount;
      return acc;
    });

    final balanceColor = myBalance > 0.01
        ? GlassColors.positive
        : myBalance < -0.01
            ? GlassColors.negative
            : hasOutstanding
                ? Colors.orange.shade300
                : GlassColors.textMuted;
    final balanceText = myBalance > 0.01
        ? '+RM ${myBalance.toStringAsFixed(2)}'
        : myBalance < -0.01
            ? '-RM ${myBalance.abs().toStringAsFixed(2)}'
            : hasOutstanding
                ? 'Unsettled'
                : 'Settled';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlassColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GlassColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(group.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 10),
            Text(group.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: GlassColors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${group.members.length} members',
                style:
                    const TextStyle(color: GlassColors.textMuted, fontSize: 12)),
            const Spacer(),
            Text(balanceText,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: balanceColor)),
            const SizedBox(height: 2),
            Text('Total RM ${group.totalExpenses.toStringAsFixed(2)}',
                style:
                    const TextStyle(color: GlassColors.textMuted, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
