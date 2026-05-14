import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/screens/add_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final group = app.getGroupById(widget.groupId);
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }

        final balances = app.calculateBalances(group);
        final myBalance = balances.fold<double>(0, (acc, b) {
          if (b.to == app.currentUser.id) return acc + b.amount;
          if (b.from == app.currentUser.id) return acc - b.amount;
          return acc;
        });
        final shownMembers = group.members.take(6).toList();

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text('${group.emoji} ${group.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilledButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(groupId: group.id),
                          ),
                        );
                        if (result == true) setState(() {});
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            body: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Summary card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).cardColor,
                          Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total spent',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                    'RM ${group.totalExpenses.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Your balance',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  myBalance > 0.01
                                      ? '+RM ${myBalance.toStringAsFixed(2)}'
                                      : myBalance < -0.01
                                          ? 'RM ${myBalance.toStringAsFixed(2)}'
                                          : 'Settled',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: myBalance > 0.01
                                        ? Color(0xFF059669)
                                        : myBalance < -0.01
                                            ? Color(0xFFE11D48)
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Member avatars
                        Row(
                          children: [
                            SizedBox(
                              width: shownMembers.isEmpty
                                  ? 0
                                  : 36 + (shownMembers.length - 1) * 30,
                              height: 36,
                              child: Stack(
                                children: shownMembers.asMap().entries.map(
                                  (entry) {
                                    final i = entry.key;
                                    final m = entry.value;
                                    return Positioned(
                                      left: i * 30,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey.shade200,
                                              width: 2),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(m.avatar,
                                            style:
                                                const TextStyle(fontSize: 16)),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                            if (group.members.length > 6)
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text('+${group.members.length - 6}',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: (index) => setState(() => _tabIndex = index),
                      indicator: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Theme.of(context).colorScheme.onSurface,
                      unselectedLabelColor: Colors.grey.shade500,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        TabRow(
                            text: 'Expenses', icon: Icons.receipt_long_rounded),
                        TabRow(
                            text: 'Balances', icon: Icons.swap_horiz_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tab content
                Builder(builder: (context) {
                  if (_tabIndex == 0) {
                    return _ExpensesTab(
                        groupId: group.id, expenses: group.expenses);
                  } else {
                    return _BalancesTab(group: group, balances: balances);
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TabRow extends StatelessWidget {
  final String text;
  final IconData icon;
  const TabRow({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final String groupId;
  final List<Expense> expenses;
  const _ExpensesTab({required this.groupId, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('No expenses yet',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Tap Add to record the first expense',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(groupId: groupId),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Expense'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: sorted.map((expense) {
          return _ExpenseCard(
            expense: expense,
            onDelete: () {
              context.read<AppProvider>().deleteExpense(groupId, expense.id);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const _ExpenseCard({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final payer = app.getUserById(expense.paidBy);
    final config = CategoryConfig.fromCategory(expense.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: config.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(config.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.description,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '${payer?.name ?? '?'} paid · ${expense.splitBetween.length} people splitting',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
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
                    Text('Each RM ${expense.perPerson.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(expense.date),
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.grey.shade400, size: 20),
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
    return '${date.year}/${date.month}/${date.day}';
  }
}

class _BalancesTab extends StatelessWidget {
  final dynamic group;
  final List<dynamic> balances;
  const _BalancesTab({required this.group, required this.balances});

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFF059669),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('✓', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 12),
              const Text('All settled',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text('This group has no outstanding expenses',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final app = context.read<AppProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Simplified settlement plan:',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 12),
          ...balances.map((b) {
            final fromUser = app.getUserById(b.from);
            final toUser = app.getUserById(b.to);
            final isMe = b.from == app.currentUser.id;
            final fromName = fromUser?.name ?? 'Unknown';
            final toName = toUser?.name ?? 'Unknown';
            final accent = isMe ? Color(0xFFE11D48) : Color(0xFF059669);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          alignment: Alignment.center,
                          child: Text(fromUser?.avatar ?? '?',
                              style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            size: 16, color: accent),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          alignment: Alignment.center,
                          child: Text(toUser?.avatar ?? '?',
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$fromName owes $toName',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          Text(
                              isMe
                                  ? 'You need to pay $toName'
                                  : toUser?.id == app.currentUser.id
                                      ? '$fromName should pay you'
                                      : 'Outstanding between members',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('RM ${b.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
