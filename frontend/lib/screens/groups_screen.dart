/*
 * groups_screen.dart — List of all visible groups
 * Each tile shows the group emoji, name, member/expense counts,
 * and your personal balance within that group.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/group.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Groups',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Manage your expense groups',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: app.groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No groups yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Tap the + button below to create a group',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: app.groups.length,
                      itemBuilder: (context, index) {
                        final group = app.groups[index];
                        return _GroupListTile(
                          group: group,
                          onTap: () => onGroupSelect(group.id),
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

class _GroupListTile extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  const _GroupListTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final balances = app.calculateBalances(group);
    final myBalance = balances.fold<double>(0, (acc, b) {
      if (b.to == app.currentUser.id) return acc + b.amount;
      if (b.from == app.currentUser.id) return acc - b.amount;
      return acc;
    });
    final total = group.totalExpenses;

    final balanceColor = myBalance > 0.01
        ? Colors.green.shade600
        : myBalance < -0.01
            ? Colors.red.shade500
            : Colors.grey;
    final balanceText = myBalance > 0.01
        ? '+RM ${myBalance.toStringAsFixed(2)}'
        : myBalance < -0.01
            ? '-RM ${myBalance.abs().toStringAsFixed(2)}'
            : 'Settled';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(group.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.group,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${group.members.length} members',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                          Text(' · ',
                              style: TextStyle(color: Colors.grey.shade400)),
                          Text('${group.expenses.length} expenses',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
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
                    Text('Total RM ${total.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
