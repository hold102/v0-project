/*
 * add_expense_screen.dart — Multi-step "add expense" wizard
 * Step 0: Select an existing group (or create a new one)
 * Step 1: Enter amount, description, category, and payer
 * Step 2: Choose which members to split between
 * Progress is shown as a 3-segment bar at the top.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/expense_category.dart';
import 'package:splitease/models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? groupId;
  final Expense? expense;
  const AddExpenseScreen({super.key, this.groupId, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

enum _SplitMode { equal, exact }

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  int _step = 0; // 0=select group, 1=details, 2=split
  String _selectedGroupId = '';
  String _description = '';
  String _amount = '';
  ExpenseCategory _category = ExpenseCategory.food;
  String _paidBy = '';
  List<String> _splitBetween = [];

  // Split mode: equal = total/N for each member. exact = per-user dollar inputs.
  _SplitMode _splitMode = _SplitMode.equal;
  // Controllers + current value for each user's exact share. Only used in exact mode.
  final Map<String, TextEditingController> _exactControllers = {};
  final Map<String, double> _exactAmounts = {};

  // New group fields
  bool _isCreating = false;
  String _newGroupName = '';
  String _newGroupEmoji = '🎉';
  List<String> _selectedMembers = [];

  final _descFocus = FocusNode();

  static const _emojis = [
    '🍕',
    '✈️',
    '🏠',
    '🎉',
    '💼',
    '🎮',
    '🛒',
    '☕',
    '🎬',
    '🏖️'
  ];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    if (widget.expense != null) {
      final e = widget.expense!;
      _selectedGroupId = e.groupId;
      _description = e.description;
      _amount = e.amount.toString();
      _category = e.category;
      _paidBy = e.paidBy;
      _splitBetween = List<String>.from(e.splitBetween);
      // Restore exact-mode if the existing expense uses custom amounts.
      if (e.splitAmounts != null && e.splitAmounts!.isNotEmpty) {
        _splitMode = _SplitMode.exact;
        _exactAmounts.addAll(e.splitAmounts!);
      }
      _step = 1;
      _selectedMembers = [app.currentUser.id];
    } else if (widget.groupId != null) {
      _selectedGroupId = widget.groupId!;
      _step = 1;
      _paidBy = app.currentUser.id;
      _selectedMembers = [app.currentUser.id];
    }
  }

  @override
  void dispose() {
    _descFocus.dispose();
    for (final c in _exactControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Make sure each member in _splitBetween has a controller in exact mode.
  // Removes controllers for members no longer in the list. Initial value:
  // existing _exactAmounts entry, else equal share of the total amount.
  void _syncExactControllers() {
    final amount = double.tryParse(_amount) ?? 0;
    final equalShare =
        _splitBetween.isNotEmpty ? amount / _splitBetween.length : 0.0;

    // Drop controllers for users no longer participating.
    final stale = _exactControllers.keys
        .where((id) => !_splitBetween.contains(id))
        .toList();
    for (final id in stale) {
      _exactControllers.remove(id)?.dispose();
      _exactAmounts.remove(id);
    }

    // Add controllers for newly added members.
    for (final id in _splitBetween) {
      if (!_exactControllers.containsKey(id)) {
        final seed = _exactAmounts[id] ?? equalShare;
        final c = TextEditingController(text: seed.toStringAsFixed(2));
        c.addListener(() {
          final v = double.tryParse(c.text);
          setState(() {
            if (v != null && v >= 0) {
              _exactAmounts[id] = v;
            } else {
              _exactAmounts.remove(id);
            }
          });
        });
        _exactControllers[id] = c;
        _exactAmounts[id] = seed;
      }
    }
  }

  double get _exactSum =>
      _exactAmounts.values.fold<double>(0, (s, v) => s + v);

  bool get _exactSumMatches {
    final amount = double.tryParse(_amount) ?? 0;
    return (_exactSum - amount).abs() <= 0.01;
  }

  void _nextStep() => setState(() => _step = (_step + 1).clamp(0, 2));
  void _prevStep() => setState(() => _step = (_step - 1).clamp(0, 2));

  void _selectGroup(String gid) {
    final app = context.read<AppProvider>();
    final group = app.getGroupById(gid);
    if (group == null) return;
    _selectedGroupId = gid;
    _splitBetween = group.members.map((m) => m.id).toList();
    _paidBy = app.currentUser.id;
    _nextStep();
  }

  void _createGroup() {
    if (_newGroupName.trim().isEmpty || _selectedMembers.length < 2) return;
    final app = context.read<AppProvider>();
    final members =
        app.users.where((u) => _selectedMembers.contains(u.id)).toList();
    final newGroup =
        app.addGroup(_newGroupName.trim(), _newGroupEmoji, members);
    _selectedGroupId = newGroup.id;
    _splitBetween = members.map((m) => m.id).toList();
    _isCreating = false;
    _nextStep();
  }

  void _submit() {
    final amount = double.tryParse(_amount);
    if (_description.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        _selectedGroupId.isEmpty ||
        _paidBy.isEmpty ||
        _splitBetween.isEmpty) {
      return;
    }
    // In exact mode, enforce sum-matches before letting the user save.
    if (_splitMode == _SplitMode.exact && !_exactSumMatches) return;

    // Build splitAmounts (only when in exact mode and the set covers everyone).
    final Map<String, double>? splitAmounts = _splitMode == _SplitMode.exact
        ? {
            for (final id in _splitBetween)
              id: (_exactAmounts[id] ?? 0).toDouble(),
          }
        : null;

    final app = context.read<AppProvider>();
    final isEditing = widget.expense != null;

    if (isEditing) {
      final updated = Expense(
        id: widget.expense!.id,
        description: _description.trim(),
        amount: amount,
        paidBy: _paidBy,
        splitBetween: _splitBetween,
        splitAmounts: splitAmounts,
        category: _category,
        date: widget.expense!.date,
        groupId: _selectedGroupId,
      );
      app.updateExpense(_selectedGroupId, updated);
    } else {
      app.addExpense(
        _selectedGroupId,
        Expense(
          id: 'e${DateTime.now().millisecondsSinceEpoch}',
          description: _description.trim(),
          amount: amount,
          paidBy: _paidBy,
          splitBetween: _splitBetween,
          splitAmounts: splitAmounts,
          category: _category,
          date: DateTime.now().toIso8601String().split('T')[0],
          groupId: _selectedGroupId,
        ),
      );
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_step == 0) {
                            Navigator.of(context).pop();
                          } else if (_step == 1) {
                            _prevStep();
                          } else {
                            _prevStep();
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _step == 0
                                  ? 'Select Group'
                                  : _step == 1
                                      ? widget.expense != null
                                          ? 'Edit Expense'
                                          : 'Add Expense'
                                      : 'Split Settings',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text('Step ${_step + 1}/3',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Row(
                    children: [
                      _ProgressSegment(filled: true),
                      const SizedBox(width: 4),
                      _ProgressSegment(filled: _step >= 1),
                      const SizedBox(width: 4),
                      _ProgressSegment(filled: _step >= 2),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Content
            Expanded(
              child: _step == 0
                  ? _buildStep0()
                  : _step == 1
                      ? _buildStep1()
                      : _buildStep2(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0() {
    if (_isCreating) return _buildCreateGroup();
    final app = context.watch<AppProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('Select a group to add an expense',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 16),
        // Create new group button
        GestureDetector(
          onTap: () => setState(() => _isCreating = true),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside),
              borderRadius: BorderRadius.circular(20),
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.auto_awesome_rounded,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Create New Group',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (app.groups.isNotEmpty) ...[
          Text('Existing Groups',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...app.groups.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _selectGroup(g.id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade100,
                                Colors.grey.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(g.emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(g.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                        Text('${g.members.length} members',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildCreateGroup() {
    final app = context.read<AppProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Emoji picker
        Text('Choose Icon',
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojis.map((e) {
            final selected = _newGroupEmoji == e;
            return GestureDetector(
              onTap: () => setState(() => _newGroupEmoji = e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Group name
        TextField(
          decoration: const InputDecoration(
            hintText: 'e.g. Weekend Dinner',
            labelText: 'Group Name',
          ),
          onChanged: (v) => setState(() => _newGroupName = v),
        ),
        const SizedBox(height: 24),
        // Member selection
        Text('Select Members (${_selectedMembers.length})',
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: app.users.map((u) {
            final selected = _selectedMembers.contains(u.id);
            final isSelf = u.id == app.currentUser.id;
            return GestureDetector(
              onTap: isSelf
                  ? null
                  : () {
                      setState(() {
                        if (selected) {
                          _selectedMembers.remove(u.id);
                        } else {
                          _selectedMembers.add(u.id);
                        }
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: (MediaQuery.of(context).size.width - 70) / 2,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.05)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child:
                          Text(u.avatar, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14))),
                    if (selected)
                      Icon(Icons.check_circle,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isCreating = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _newGroupName.trim().isNotEmpty &&
                        _selectedMembers.length >= 2
                    ? _createGroup
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create Group'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final app = context.watch<AppProvider>();
    final group = app.getGroupById(_selectedGroupId);

    final amount = double.tryParse(_amount);
    final canContinue =
        amount != null && amount > 0 && _description.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Selected group info
        if (group != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
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
                  child:
                      Text(group.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('${group.members.length} members',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        // Amount
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, top: 14),
              child: Text('RM',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400)),
            ),
          ),
          onChanged: (v) => setState(() => _amount = v),
        ),
        const SizedBox(height: 24),
        // Description
        TextField(
          focusNode: _descFocus,
          decoration: const InputDecoration(
            hintText: 'What was this expense for?',
            labelText: 'Description',
          ),
          onChanged: (v) => setState(() => _description = v),
        ),
        const SizedBox(height: 24),
        // Category
        Text('Category',
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CategoryConfig.configs.entries.map((entry) {
            final cat = entry.key;
            final config = entry.value;
            final selected = _category == cat;
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: (MediaQuery.of(context).size.width - 68) / 4,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(config.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(config.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Payer
        Text('Who paid?',
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (group != null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.members.map((m) {
              final selected = _paidBy == m.id;
              return GestureDetector(
                onTap: () => setState(() => _paidBy = m.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.avatar, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(m.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: canContinue ? _nextStep : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Next: Set Split', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final app = context.watch<AppProvider>();
    final group = app.getGroupById(_selectedGroupId);
    final amount = double.tryParse(_amount) ?? 0;
    final perPerson =
        _splitBetween.isNotEmpty ? amount / _splitBetween.length : 0;

    // Keep controllers in sync with the current splitBetween + amount.
    if (_splitMode == _SplitMode.exact) {
      _syncExactControllers();
    }
    final remaining = amount - _exactSum;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Text('Total Amount',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Text('RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_splitBetween.length} people splitting',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text('Each RM ${perPerson.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Split-mode toggle: Equal vs Exact
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SplitModeChip(
                  label: 'Equal',
                  selected: _splitMode == _SplitMode.equal,
                  onTap: () => setState(() {
                    _splitMode = _SplitMode.equal;
                    // discard any partial exact data
                    for (final c in _exactControllers.values) {
                      c.dispose();
                    }
                    _exactControllers.clear();
                    _exactAmounts.clear();
                  }),
                ),
              ),
              Expanded(
                child: _SplitModeChip(
                  label: 'Exact amounts',
                  selected: _splitMode == _SplitMode.exact,
                  onTap: () => setState(() {
                    _splitMode = _SplitMode.exact;
                    _syncExactControllers();
                  }),
                ),
              ),
            ],
          ),
        ),
        if (_splitMode == _SplitMode.exact) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _exactSumMatches
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _exactSumMatches
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.orange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _exactSumMatches
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 18,
                  color:
                      _exactSumMatches ? Colors.green.shade700 : Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _exactSumMatches
                        ? 'Amounts match total — ready to save.'
                        : remaining > 0
                            ? 'Remaining: RM ${remaining.toStringAsFixed(2)} unassigned'
                            : 'Over by RM ${(-remaining).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _exactSumMatches
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text('Who should split this?',
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (group != null)
          ...group.members.map((m) {
            final isIncluded = _splitBetween.contains(m.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isIncluded) {
                      _splitBetween.remove(m.id);
                    } else {
                      _splitBetween.add(m.id);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isIncluded
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.05)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isIncluded
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      width: isIncluded ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(m.avatar,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(m.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (isIncluded && _splitMode == _SplitMode.equal)
                        Text('RM ${perPerson.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            )),
                      if (isIncluded && _splitMode == _SplitMode.exact)
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _exactControllers[m.id],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixText: 'RM ',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isIncluded
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          color: isIncluded
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: isIncluded
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: (amount > 0 &&
                        _paidBy.isNotEmpty &&
                        _splitBetween.isNotEmpty &&
                        (_splitMode == _SplitMode.equal || _exactSumMatches))
                    ? _submit
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(widget.expense != null ? 'Save Changes' : 'Save Expense'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SplitModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SplitModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final bool filled;
  const _ProgressSegment({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: filled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
