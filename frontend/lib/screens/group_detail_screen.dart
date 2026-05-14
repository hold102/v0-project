/*
 * group_detail_screen.dart — Single group view with Expenses & Balances tabs
 * Shows a summary card (total spent, your balance, member avatars),
 * then a tab bar to switch between the expense list and the settlement plan.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/balance.dart';
import 'package:splitease/screens/add_expense_screen.dart';
import 'package:splitease/screens/edit_group_screen.dart';
import 'package:splitease/services/api_service.dart';
import 'package:splitease/theme/app_theme.dart';

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

  void _showAddMemberSheet(BuildContext context, String groupId) {
    final emailController = TextEditingController();
    String? errorText;
    Map<String, dynamic>? foundUser;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Add Member',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter email address',
                      errorText: errorText,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (foundUser != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(foundUser!['avatar'] ?? '👤',
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text(foundUser!['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  setSheetState(() {
                                    errorText = null;
                                    loading = true;
                                    foundUser = null;
                                  });
                                  try {
                                    final user = await ApiService()
                                        .lookupUserByEmail(
                                            emailController.text.trim());
                                    setSheetState(() {
                                      foundUser = {
                                        'id': user.id,
                                        'name': user.name,
                                        'avatar': user.avatar,
                                      };
                                      loading = false;
                                    });
                                  } catch (e) {
                                    setSheetState(() {
                                      errorText = e.toString().replaceFirst(
                                          'Exception: ', '');
                                      loading = false;
                                    });
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Text('Look up'),
                        ),
                      ),
                      if (foundUser != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              try {
                                await context
                                    .read<AppProvider>()
                                    .addMemberToGroup(
                                        groupId, foundUser!['id']);
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              } catch (e) {
                                setSheetState(() {
                                  errorText = e
                                      .toString()
                                      .replaceFirst('Exception: ', '');
                                });
                              }
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Add to Group'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditGroupScreen(groupId: group.id),
                        ),
                      );
                      if (result == true) setState(() {});
                    },
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 18),
                    ),
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).cardColor,
                          Colors.grey.shade50,
                        ],
                      ),
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
                                        ? AppColors.positiveBalance
                                        : myBalance < -0.01
                                            ? AppColors.negativeBalance
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
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showAddMemberSheet(context, group.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_add_rounded,
                                        size: 15,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text('Add',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        _TabRow(
                            text: 'Expenses', icon: Icons.receipt_long_rounded),
                        _TabRow(
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

class _TabRow extends StatelessWidget {
  final String text;
  final IconData icon;
  const _TabRow({required this.text, required this.icon});

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
    final hasRealExpenses = expenses.any((e) => e.category != ExpenseCategory.settlement);

    if (!hasRealExpenses) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.receipt_long_rounded,
                    size: 36, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              const Text('No expenses yet',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Tap Add to record the first expense',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: sorted.map((expense) {
          return _ExpenseCard(
            expense: expense,
            onDelete: () {
              context.read<AppProvider>().deleteExpense(groupId, expense.id);
            },
            onTap: () => _showExpenseDetail(context, expense, expenses),
          );
        }).toList(),
      ),
    );
  }

  void _showExpenseDetail(BuildContext context, Expense expense, List<Expense> allExpenses) {
    final app = context.read<AppProvider>();
    final payer = app.getUserById(expense.paidBy);
    final config = CategoryConfig.fromCategory(expense.category);

    // A member is settled if they are the payer (already covered their share)
    // or if a settlement expense exists from them to the payer.
    bool isSettled(String userId) {
      if (userId == expense.paidBy) return true;
      return allExpenses.any((e) =>
          e.category == ExpenseCategory.settlement &&
          e.paidBy == userId &&
          e.splitBetween.contains(expense.paidBy));
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: config.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(config.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(expense.date,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('RM ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Paid by',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(payer?.avatar ?? '👤',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(payer?.name ?? '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  Text('RM ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Split between',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              ...expense.splitBetween.map((uid) {
                final user = app.getUserById(uid);
                final share = expense.splitAmounts?[uid] ?? expense.perPerson;
                final settled = isSettled(uid);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(user?.avatar ?? '👤',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(user?.name ?? '?',
                            style: TextStyle(
                                fontSize: 15,
                                color: settled
                                    ? Colors.grey.shade400
                                    : null)),
                      ),
                      if (settled)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.settledGreen, size: 18)
                      else
                        Text('RM ${share.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _ExpenseCard({required this.expense, required this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final payer = app.getUserById(expense.paidBy);
    final config = CategoryConfig.fromCategory(expense.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                        expense.category == ExpenseCategory.settlement
                            ? '${payer?.name ?? '?'} paid ${app.getUserById(expense.splitBetween.firstOrNull ?? '')?.name ?? '?'}'
                            : '${payer?.name ?? '?'} paid · ${expense.splitBetween.length} people splitting',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                expense.category == ExpenseCategory.settlement
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.positiveBalance.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Settled',
                            style: TextStyle(
                                color: AppColors.positiveBalance,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      )
                    : Column(
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
  final Group group;
  final List<Balance> balances;
  const _BalancesTab({required this.group, required this.balances});

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 36, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 16),
              const Text('All settled up!',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text('This group has no outstanding balances',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final app = context.read<AppProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            final accent = isMe ? AppColors.negativeBalance : AppColors.positiveBalance;

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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        context.read<AppProvider>().recordSettlement(
                              group.id,
                              b.from,
                              b.to,
                              b.amount,
                            );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.check_rounded, size: 20, color: accent),
                      ),
                    ),
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
