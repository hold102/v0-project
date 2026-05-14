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
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(group.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${group.members.length} members',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            const SizedBox(height: 4),
            Text(balanceText,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: balanceColor)),
            Text('Total RM ${group.totalExpenses.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
