import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/balance.dart';
import 'package:splitease/screens/add_expense_screen.dart';
import 'package:splitease/screens/edit_group_screen.dart';
import 'package:splitease/services/fx_service.dart';
import 'package:splitease/theme/app_theme.dart';
import 'package:splitease/widgets/glass_card.dart';
import 'package:splitease/widgets/user_search_field.dart';

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
    final app = context.read<AppProvider>();
    final group = app.getGroupById(groupId);
    final existingIds = group?.members.map((m) => m.id).toSet() ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1535),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Member',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GlassColors.text)),
              const SizedBox(height: 4),
              const Text('Search by name or email',
                  style:
                      TextStyle(color: GlassColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              UserSearchField(
                excludeIds: existingIds,
                onUserSelected: (user) async {
                  try {
                    await context
                        .read<AppProvider>()
                        .addMemberToGroup(groupId, user.id);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
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
            backgroundColor: GlassColors.bgColors[0],
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: const Center(
                child: Text('Group not found',
                    style: TextStyle(color: GlassColors.text))),
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
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Container(
                  decoration: const BoxDecoration(
                      gradient: GlassColors.bgGradient)),
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: GlassColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GlassColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: Colors.white),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: Text('${group.emoji} ${group.name}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    actions: [
                      IconButton(
                        onPressed: () async {
                          final result =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditGroupScreen(groupId: group.id),
                            ),
                          );
                          if (result == true) setState(() {});
                        },
                        icon: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: GlassColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: GlassColors.border),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextButton.icon(
                            onPressed: () async {
                              final result =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddExpenseScreen(groupId: group.id),
                                ),
                              );
                              if (result == true) setState(() {});
                            },
                            icon: const Icon(Icons.add,
                                size: 16, color: Colors.white),
                            label: const Text('Add',
                                style: TextStyle(color: Colors.white)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                body: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    if (group.description.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: GlassColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: GlassColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_rounded,
                                  size: 16, color: GlassColors.textMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  group.description,
                                  style: const TextStyle(
                                      color: GlassColors.text,
                                      fontSize: 13,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Summary card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total amount',
                                        style: TextStyle(
                                            color: GlassColors.textMuted,
                                            fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'RM ${group.totalExpenses.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: GlassColors.text)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        myBalance > 0.01
                                            ? 'You lent'
                                            : myBalance < -0.01
                                                ? 'You owe'
                                                : 'Your balance',
                                        style: const TextStyle(
                                            color: GlassColors.textMuted,
                                            fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      myBalance > 0.01
                                          ? 'RM ${myBalance.toStringAsFixed(2)}'
                                          : myBalance < -0.01
                                              ? 'RM ${myBalance.abs().toStringAsFixed(2)}'
                                              : 'Settled',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: myBalance > 0.01
                                            ? GlassColors.positive
                                            : myBalance < -0.01
                                                ? GlassColors.negative
                                                : GlassColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: shownMembers.isEmpty
                                      ? 0
                                      : 36 +
                                          (shownMembers.length - 1) * 30,
                                  height: 36,
                                  child: Stack(
                                    children: shownMembers
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final i = entry.key;
                                      final m = entry.value;
                                      return Positioned(
                                        left: i * 30,
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: GlassColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: GlassColors.border,
                                                width: 2),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(m.avatar,
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                if (group.members.length > 6)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                        '+${group.members.length - 6}',
                                        style: const TextStyle(
                                            color: GlassColors.textMuted,
                                            fontSize: 13)),
                                  ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _showAddMemberSheet(
                                      context, group.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: GlassColors.surface,
                                      border: Border.all(
                                          color: GlassColors.border),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_add_rounded,
                                            size: 14,
                                            color: GlassColors.textMuted),
                                        SizedBox(width: 4),
                                        Text('Add',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: GlassColors.textMuted,
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
                    const SizedBox(height: 20),
                    // Tab bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: GlassColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GlassColors.border),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          onTap: (i) => setState(() => _tabIndex = i),
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: GlassColors.textMuted,
                          padding: const EdgeInsets.all(4),
                          tabs: const [
                            _TabRow(
                                text: 'Expenses',
                                icon: Icons.receipt_long_rounded),
                            _TabRow(
                                text: 'Balances',
                                icon: Icons.swap_horiz_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(builder: (context) {
                      if (_tabIndex == 0) {
                        return _ExpensesTab(
                            groupId: group.id, expenses: group.expenses);
                      } else {
                        return _BalancesTab(
                            group: group, balances: balances);
                      }
                    }),
                  ],
                ),
              ),
            ],
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
          Icon(icon, size: 16),
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
    final hasRealExpenses =
        expenses.any((e) => e.category != ExpenseCategory.settlement);

    if (!hasRealExpenses) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassTile(
          borderRadius: 20,
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: GlassColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlassColors.border),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.receipt_long_rounded,
                    size: 36, color: GlassColors.textMuted),
              ),
              const SizedBox(height: 16),
              const Text('No expenses yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: GlassColors.text)),
              const SizedBox(height: 8),
              const Text('Tap Add to record the first expense',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: GlassColors.textMuted, fontSize: 13)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(groupId: groupId),
                    ));
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Add Expense',
                      style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Settlements no longer appear as separate rows in the expense list — they
    // surface only via the per-payer tick mark inside an expense's detail sheet.
    // `expenses` (the full list) is still passed to `_showExpenseDetail` so the
    // isSettled() check can find the underlying settlement records.
    final sorted = expenses
        .where((e) => e.category != ExpenseCategory.settlement)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: sorted
            .map((expense) => _ExpenseCard(
                  expense: expense,
                  allExpenses: expenses,
                  onDelete: () => context
                      .read<AppProvider>()
                      .deleteExpense(groupId, expense.id),
                  onTap: () =>
                      _showExpenseDetail(context, expense, expenses),
                ))
            .toList(),
      ),
    );
  }

  void _showExpenseDetail(
      BuildContext context, Expense expense, List<Expense> allExpenses) {
    final app = context.read<AppProvider>();
    final payer = app.getUserById(expense.paidBy);
    final config = CategoryConfig.fromCategory(expense.category);

    // Balance-based settled check: a splitter is settled iff their cumulative
    // settlement payments to the payer (across this whole group) cover their
    // cumulative share of every non-settlement expense the payer paid for.
    // This prevents a single partial settlement from auto-ticking unrelated rows.
    bool isSettled(String userId) {
      if (userId == expense.paidBy) return true; // payer doesn't owe self
      double owed = 0;
      double paid = 0;
      for (final e in allExpenses) {
        if (e.category == ExpenseCategory.settlement) {
          if (e.paidBy == userId && e.splitBetween.contains(expense.paidBy)) {
            paid += e.amount;
          }
        } else if (e.paidBy == expense.paidBy &&
            e.splitBetween.contains(userId) &&
            userId != expense.paidBy) {
          owed += e.splitAmounts?[userId] ?? e.perPerson;
        }
      }
      return paid + 0.01 >= owed;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1535),
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: GlassColors.text)),
                        const SizedBox(height: 2),
                        Text(expense.date,
                            style: const TextStyle(
                                color: GlassColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('RM ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: GlassColors.text)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('PAID BY',
                  style: TextStyle(
                      color: GlassColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(payer?.avatar ?? '👤',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(payer == null ? '?' : app.displayName(payer),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: GlassColors.text)),
                  const Spacer(),
                  Text('RM ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: GlassColors.text)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('SPLIT BETWEEN',
                  style: TextStyle(
                      color: GlassColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              ...expense.splitBetween.map((uid) {
                final user = app.getUserById(uid);
                final share =
                    expense.splitAmounts?[uid] ?? expense.perPerson;
                final settled = isSettled(uid);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(user?.avatar ?? '👤',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(user == null ? '?' : app.displayName(user),
                            style: TextStyle(
                                fontSize: 15,
                                color: settled
                                    ? GlassColors.textMuted
                                    : GlassColors.text)),
                      ),
                      if (settled)
                        const Icon(Icons.check_circle_rounded,
                            color: GlassColors.positive, size: 18)
                      else
                        Text('RM ${share.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 15, color: GlassColors.text)),
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
  final List<Expense> allExpenses;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _ExpenseCard({
    required this.expense,
    required this.allExpenses,
    required this.onDelete,
    this.onTap,
  });

  // Fully settled = every non-payer splitter's cumulative settlement payments
  // to the payer cover their cumulative share of this payer's expenses.
  // Matches the per-row check in _showExpenseDetail.isSettled — both use a
  // balance comparison rather than just "has any settlement record exists".
  bool _isFullySettled() {
    if (expense.category == ExpenseCategory.settlement) return false;
    final others = expense.splitBetween
        .where((uid) => uid != expense.paidBy)
        .toList();
    if (others.isEmpty) return false;

    bool settledFor(String uid) {
      double owed = 0;
      double paid = 0;
      for (final e in allExpenses) {
        if (e.category == ExpenseCategory.settlement) {
          if (e.paidBy == uid && e.splitBetween.contains(expense.paidBy)) {
            paid += e.amount;
          }
        } else if (e.paidBy == expense.paidBy &&
            e.splitBetween.contains(uid)) {
          owed += e.splitAmounts?[uid] ?? e.perPerson;
        }
      }
      return paid + 0.01 >= owed;
    }

    return others.every(settledFor);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final payer = app.getUserById(expense.paidBy);
    final config = CategoryConfig.fromCategory(expense.category);
    final settled = _isFullySettled();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassTile(
        borderRadius: 18,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
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
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: GlassColors.text)),
                      const SizedBox(height: 2),
                      Text(
                        expense.category == ExpenseCategory.settlement
                            ? '${payer == null ? '?' : app.displayName(payer)} paid ${app.displayNameById(expense.splitBetween.firstOrNull)}'
                            : '${payer == null ? '?' : app.displayName(payer)} paid · ${expense.splitBetween.length} people',
                        style: const TextStyle(
                            color: GlassColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                expense.category == ExpenseCategory.settlement
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GlassColors.positive.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Settled',
                            style: TextStyle(
                                color: GlassColors.positive,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      )
                    : Builder(builder: (_) {
                        final viewerCurrency = context
                            .read<AppProvider>()
                            .currentUser
                            .currency;
                        final converted = FxService().convert(
                            expense.amount,
                            expense.currency,
                            viewerCurrency);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                FxService().format(
                                    expense.amount, expense.currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: GlassColors.text)),
                            if (expense.currency != viewerCurrency &&
                                converted != null)
                              Text(
                                  '≈ ${FxService().format(converted, viewerCurrency)}',
                                  style: const TextStyle(
                                      color: GlassColors.textMuted,
                                      fontSize: 11)),
                            const SizedBox(height: 4),
                            if (settled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: GlassColors.positive
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: GlassColors.positive
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: GlassColors.positive,
                                        size: 12),
                                    SizedBox(width: 4),
                                    Text('Settled',
                                        style: TextStyle(
                                            color: GlassColors.positive,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11)),
                                  ],
                                ),
                              )
                            else
                              Text(
                                  'Each ${FxService().format(expense.perPerson, expense.currency)}',
                                  style: const TextStyle(
                                      color: GlassColors.textMuted,
                                      fontSize: 12)),
                          ],
                        );
                      }),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
                color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(expense.date),
                    style: const TextStyle(
                        color: GlassColors.textMuted, fontSize: 12)),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: GlassColors.textMuted, size: 20),
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
  final Group group;
  final List<Balance> balances;
  const _BalancesTab({required this.group, required this.balances});

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassTile(
          borderRadius: 20,
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: GlassColors.positive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: GlassColors.positive.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 36, color: GlassColors.positive),
              ),
              const SizedBox(height: 16),
              const Text('All settled up!',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: GlassColors.text)),
              const SizedBox(height: 8),
              const Text('This group has no outstanding balances',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: GlassColors.textMuted, fontSize: 13)),
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
          const Text('Simplified settlement plan:',
              style: TextStyle(color: GlassColors.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          ...balances.map((b) {
            final fromUser = app.getUserById(b.from);
            final toUser = app.getUserById(b.to);
            final isMe = b.from == app.currentUser.id;
            final fromName =
                fromUser == null ? 'Unknown' : app.displayName(fromUser);
            final toName =
                toUser == null ? 'Unknown' : app.displayName(toUser);
            final accent =
                isMe ? GlassColors.negative : GlassColors.positive;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: GlassColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: GlassColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(fromUser?.avatar ?? '?',
                              style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: accent),
                        const SizedBox(width: 6),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: GlassColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: GlassColors.border),
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
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: GlassColors.text)),
                          Text(
                            isMe
                                ? 'You need to pay $toName'
                                : toUser?.id == app.currentUser.id
                                    ? '$fromName should pay you'
                                    : 'Outstanding between members',
                            style: const TextStyle(
                                color: GlassColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text('RM ${b.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: accent)),
                    const SizedBox(width: 8),
                    // Only the payee (the user being owed money) can tick the
                    // payment as received — debtors can't mark themselves paid.
                    if (b.to == app.currentUser.id)
                      GestureDetector(
                        onTap: () => context
                            .read<AppProvider>()
                            .recordSettlement(
                                group.id, b.from, b.to, b.amount),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.check_rounded,
                              size: 18, color: accent),
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
