/*
 * group_card.dart — A compact horizontal card for the home screen carousel
 * Shows emoji, name, member count, and the current user's balance status.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final balances = app.calculateBalances(group);
    final hasOutstandingBalances = balances.isNotEmpty;
    final myBalance = balances.fold<double>(0, (acc, b) {
      if (b.to == app.currentUser.id) return acc + b.amount;
      if (b.from == app.currentUser.id) return acc - b.amount;
      return acc;
    });

    final balanceColor = myBalance > 0.01
        ? Colors.green.shade600
        : myBalance < -0.01
            ? Colors.red.shade500
            : hasOutstandingBalances
                ? Colors.orange.shade700
                : Colors.grey;
    final balanceText = myBalance > 0.01
        ? '+RM ${myBalance.toStringAsFixed(2)}'
        : myBalance < -0.01
            ? '-RM ${myBalance.abs().toStringAsFixed(2)}'
            : hasOutstandingBalances
                ? 'Unsettled'
                : 'Settled';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(group.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 10),
            Text(group.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${group.members.length} members',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const Spacer(),
            Text(balanceText,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: balanceColor)),
            const SizedBox(height: 2),
            Text('Total RM ${group.totalExpenses.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
