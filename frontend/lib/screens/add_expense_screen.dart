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
import 'package:splitease/models/user.dart';
import 'package:splitease/services/fx_service.dart';
import 'package:splitease/theme/app_theme.dart';
import 'package:splitease/widgets/user_search_field.dart';

InputDecoration _glassInput({
  String? hint,
  String? label,
  String? errorText,
  Widget? prefixIcon,
  bool isDense = false,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    hintText: hint,
    labelText: label,
    errorText: errorText,
    prefixIcon: prefixIcon,
    isDense: isDense,
    hintStyle: const TextStyle(color: GlassColors.textMuted),
    labelStyle: const TextStyle(color: GlassColors.textMuted),
    errorStyle: const TextStyle(color: GlassColors.negative),
    filled: true,
    fillColor: GlassColors.surface,
    contentPadding:
        contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: GlassColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: GlassColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white54),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: GlassColors.negative.withValues(alpha: 0.6)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: GlassColors.negative),
    ),
  );
}

class AddExpenseScreen extends StatefulWidget {
  final String? groupId;
  final Expense? expense;
  const AddExpenseScreen({super.key, this.groupId, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

enum _SplitMode { equal, exact }

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  int _step = 0;
  String _selectedGroupId = '';
  String _description = '';
  String _amount = '';
  String _currency = 'MYR';
  ExpenseCategory _category = ExpenseCategory.food;
  String _paidBy = '';
  List<String> _splitBetween = [];

  _SplitMode _splitMode = _SplitMode.equal;
  final Map<String, TextEditingController> _exactControllers = {};
  final Map<String, double> _exactAmounts = {};

  bool _isCreating = false;
  String _newGroupName = '';
  String _newGroupDescription = '';
  String _newGroupEmoji = '🎉';
  List<User> _selectedMembers = [];

  final _descFocus = FocusNode();

  static const _emojis = [
    '🍕', '✈️', '🏠', '🎉', '💼', '🎮', '🛒', '☕', '🎬', '🏖️'
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
      _currency = e.currency;
      _category = e.category;
      _paidBy = e.paidBy;
      _splitBetween = List<String>.from(e.splitBetween);
      if (e.splitAmounts != null && e.splitAmounts!.isNotEmpty) {
        _splitMode = _SplitMode.exact;
        _exactAmounts.addAll(e.splitAmounts!);
      }
      _step = 1;
      _selectedMembers = [app.currentUser];
    } else if (widget.groupId != null) {
      _selectedGroupId = widget.groupId!;
      _step = 1;
      _paidBy = app.currentUser.id;
      _selectedMembers = [app.currentUser];
      _currency = app.currentUser.currency;
    } else {
      // Launched from the global "+" button — go straight to create-group form.
      // Expense creation for existing groups happens from the group detail screen.
      _isCreating = true;
      _selectedMembers = [app.currentUser];
      _currency = app.currentUser.currency;
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

  void _syncExactControllers() {
    final amount = double.tryParse(_amount) ?? 0;
    final equalShare =
        _splitBetween.isNotEmpty ? amount / _splitBetween.length : 0.0;

    final stale = _exactControllers.keys
        .where((id) => !_splitBetween.contains(id))
        .toList();
    for (final id in stale) {
      _exactControllers.remove(id)?.dispose();
      _exactAmounts.remove(id);
    }

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
    final newGroup = app.addGroup(
      _newGroupName.trim(),
      _newGroupEmoji,
      _selectedMembers,
      description: _newGroupDescription.trim(),
    );
    _selectedGroupId = newGroup.id;
    _splitBetween = _selectedMembers.map((m) => m.id).toList();
    _isCreating = false;
    _nextStep();
  }

  void _submit() {
    final rawAmount = double.tryParse(_amount);
    if (_description.trim().isEmpty ||
        rawAmount == null ||
        rawAmount <= 0 ||
        _selectedGroupId.isEmpty ||
        _paidBy.isEmpty ||
        _splitBetween.isEmpty) {
      return;
    }
    if (_splitMode == _SplitMode.exact && !_exactSumMatches) return;

    // Convert the entered amount + custom splits from the chosen currency to
    // MYR at submit time, so the database only ever stores MYR. This keeps all
    // totals/balances consistent — no mixed-currency summing anywhere.
    double toMyr(double v) =>
        FxService().convert(v, _currency, 'MYR') ?? v;

    final amount = toMyr(rawAmount);

    final Map<String, double>? splitAmounts = _splitMode == _SplitMode.exact
        ? {
            for (final id in _splitBetween)
              id: toMyr((_exactAmounts[id] ?? 0).toDouble()),
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
        currency: 'MYR',
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
          currency: 'MYR',
        ),
      );
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: GlassColors.bgGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_step == 0) {
                                Navigator.of(context).pop();
                              } else {
                                _prevStep();
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: GlassColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: GlassColors.border),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  size: 20, color: GlassColors.text),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _step == 0
                                      ? (_isCreating ? 'Create Group' : 'Select Group')
                                      : _step == 1
                                          ? widget.expense != null
                                              ? 'Edit Expense'
                                              : 'Add Expense'
                                          : 'Split Settings',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: GlassColors.text),
                                ),
                                Text('Step ${_step + 1}/3',
                                    style: const TextStyle(
                                        color: GlassColors.textMuted,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _ProgressSegment(filled: true),
                          const SizedBox(width: 6),
                          _ProgressSegment(filled: _step >= 1),
                          const SizedBox(width: 6),
                          _ProgressSegment(filled: _step >= 2),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
        ],
      ),
    );
  }

  Widget _buildStep0() {
    if (_isCreating) return _buildCreateGroup();
    final app = context.watch<AppProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const Text('Select a group to add an expense',
            style: TextStyle(color: GlassColors.textMuted, fontSize: 14)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              _isCreating = true;
              _selectedMembers = [app.currentUser];
              _newGroupName = '';
              _newGroupEmoji = '🎉';
            });
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF764BA2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF764BA2).withValues(alpha: 0.4),
                  width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF764BA2).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF9B7FD4)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Create New Group',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: GlassColors.text)),
                ),
                const Icon(Icons.chevron_right,
                    color: GlassColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (app.groups.isNotEmpty) ...[
          const Text('Existing Groups',
              style: TextStyle(
                  color: GlassColors.textMuted,
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
                      color: GlassColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlassColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: GlassColors.text)),
                        ),
                        Text('${g.members.length} members',
                            style: const TextStyle(
                                color: GlassColors.textMuted, fontSize: 13)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            color: GlassColors.textMuted, size: 20),
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
    final canCreate =
        _newGroupName.trim().isNotEmpty && _selectedMembers.length >= 2;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const Text('Choose Icon',
            style: TextStyle(
                color: GlassColors.textMuted,
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
                      ? const Color(0xFF764BA2)
                      : GlassColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF764BA2)
                        : GlassColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        TextField(
          style: const TextStyle(color: GlassColors.text),
          decoration: _glassInput(
            hint: 'e.g. Weekend Dinner',
            label: 'Group Name',
          ),
          onChanged: (v) => setState(() => _newGroupName = v),
        ),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(color: GlassColors.text),
          minLines: 1,
          maxLines: 3,
          decoration: _glassInput(
            hint: 'What\'s this group for? (optional)',
            label: 'Description',
          ),
          onChanged: (v) => setState(() => _newGroupDescription = v),
        ),
        const SizedBox(height: 24),
        Text('Add Members (${_selectedMembers.length})',
            style: const TextStyle(
                color: GlassColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (app.friends.isNotEmpty) ...[
          const Text('Pick from your friends',
              style: TextStyle(
                  color: GlassColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: app.friends.map((friend) {
              final picked =
                  _selectedMembers.any((m) => m.id == friend.id);
              return GestureDetector(
                onTap: () => setState(() {
                  if (picked) {
                    _selectedMembers = _selectedMembers
                        .where((m) => m.id != friend.id)
                        .toList();
                  } else {
                    _selectedMembers = [..._selectedMembers, friend];
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: picked
                        ? const Color(0xFF764BA2)
                        : GlassColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: picked
                          ? const Color(0xFF764BA2)
                          : GlassColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(friend.avatar,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(friend.name,
                          style: TextStyle(
                            color: picked
                                ? Colors.white
                                : GlassColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(width: 4),
                      Icon(
                        picked
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        size: 14,
                        color: picked
                            ? Colors.white
                            : GlassColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('Or search anyone',
              style: TextStyle(
                  color: GlassColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
        ],
        UserSearchField(
          excludeIds: _selectedMembers.map((m) => m.id).toSet(),
          onUserSelected: (user) =>
              setState(() => _selectedMembers = [..._selectedMembers, user]),
        ),
        if (_selectedMembers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMembers.map((u) {
              final isSelf = u.id == app.currentUser.id;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GlassColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlassColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(u.avatar, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(isSelf ? 'You' : u.name,
                        style: const TextStyle(
                            color: GlassColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    if (!isSelf) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _selectedMembers =
                            _selectedMembers
                                .where((m) => m.id != u.id)
                                .toList()),
                        child: const Icon(Icons.close,
                            size: 14, color: GlassColors.textMuted),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: GlassColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GlassColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: GlassColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: canCreate ? _createGroup : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: canCreate
                        ? const LinearGradient(
                            colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canCreate ? null : GlassColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('Create Group',
                      style: TextStyle(
                          color: canCreate
                              ? Colors.white
                              : GlassColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (group != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GlassColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GlassColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassColors.border),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: GlassColors.text)),
                    Text('${group.members.length} members',
                        style: const TextStyle(
                            color: GlassColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // Currency selector chip above the amount field — tap to switch.
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () async {
              final picked =
                  await _pickCurrency(context, _currency);
              if (picked != null) setState(() => _currency = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: GlassColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GlassColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${FxService.symbolFor(_currency)} $_currency',
                    style: const TextStyle(
                        color: GlassColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: GlassColors.textMuted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: GlassColors.text),
          textAlign: TextAlign.center,
          decoration: _glassInput(
            hint: '0.00',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, top: 14),
              child: Text(FxService.symbolFor(_currency),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: GlassColors.textMuted)),
            ),
          ),
          onChanged: (v) => setState(() => _amount = v),
        ),
        // Show a small "≈ in your currency" preview when the expense currency
        // differs from the viewer's preferred currency.
        if (_amount.isNotEmpty &&
            double.tryParse(_amount) != null &&
            _currency != app.currentUser.currency) ...[
          const SizedBox(height: 6),
          Builder(builder: (_) {
            final native = double.parse(_amount);
            final converted = FxService().convert(
                native, _currency, app.currentUser.currency);
            if (converted == null) return const SizedBox.shrink();
            return Center(
              child: Text(
                '≈ ${FxService().format(converted, app.currentUser.currency)}',
                style: const TextStyle(
                    color: GlassColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
        TextField(
          focusNode: _descFocus,
          style: const TextStyle(color: GlassColors.text),
          decoration: _glassInput(
            hint: 'What was this expense for?',
            label: 'Description',
          ),
          onChanged: (v) => setState(() => _description = v),
        ),
        const SizedBox(height: 24),
        const Text('Category',
            style: TextStyle(
                color: GlassColors.textMuted,
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
                      ? const Color(0xFF764BA2)
                      : GlassColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF764BA2)
                        : GlassColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(config.emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(config.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : GlassColors.textMuted,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Who paid?',
            style: TextStyle(
                color: GlassColors.textMuted,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF764BA2)
                        : GlassColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF764BA2)
                          : GlassColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.avatar, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(m.id == app.currentUser.id ? 'You' : m.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : GlassColors.text,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: canContinue ? _nextStep : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: canContinue
                  ? const LinearGradient(
                      colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: canContinue ? null : GlassColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              'Next: Set Split',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: canContinue ? Colors.white : GlassColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2() {
    final app = context.watch<AppProvider>();
    final group = app.getGroupById(_selectedGroupId);
    final amount = double.tryParse(_amount) ?? 0;
    final double perPerson =
        _splitBetween.isNotEmpty ? amount / _splitBetween.length : 0;

    if (_splitMode == _SplitMode.exact) {
      _syncExactControllers();
    }
    final remaining = amount - _exactSum;
    final canSave = amount > 0 &&
        _paidBy.isNotEmpty &&
        _splitBetween.isNotEmpty &&
        (_splitMode == _SplitMode.equal || _exactSumMatches);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF764BA2).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF764BA2).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              const Text('Total Amount',
                  style:
                      TextStyle(color: GlassColors.textMuted, fontSize: 13)),
              const SizedBox(height: 4),
              Text(FxService().format(amount, _currency),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: GlassColors.text)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF764BA2).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_splitBetween.length} people splitting',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9B7FD4),
                        )),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: GlassColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlassColors.border),
                    ),
                    child: Text(
                        'Each ${FxService().format(perPerson, _currency)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GlassColors.text)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: GlassColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GlassColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SplitModeChip(
                  label: 'Equal',
                  selected: _splitMode == _SplitMode.equal,
                  onTap: () => setState(() {
                    _splitMode = _SplitMode.equal;
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _exactSumMatches
                  ? GlassColors.positive.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _exactSumMatches
                    ? GlassColors.positive.withValues(alpha: 0.4)
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
                  color: _exactSumMatches
                      ? GlassColors.positive
                      : Colors.orange.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _exactSumMatches
                        ? 'Amounts match total — ready to save.'
                        : remaining > 0
                            ? 'Remaining: ${FxService().format(remaining, _currency)} unassigned'
                            : 'Over by ${FxService().format(-remaining, _currency)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _exactSumMatches
                          ? GlassColors.positive
                          : Colors.orange.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text('Who should split this?',
            style: TextStyle(
                color: GlassColors.textMuted,
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
                        ? const Color(0xFF764BA2).withValues(alpha: 0.12)
                        : GlassColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isIncluded
                          ? const Color(0xFF764BA2).withValues(alpha: 0.5)
                          : GlassColors.border,
                      width: isIncluded ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(m.avatar,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(m.id == app.currentUser.id ? 'You' : m.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: GlassColors.text)),
                      ),
                      if (isIncluded && _splitMode == _SplitMode.equal)
                        Text(FxService().format(perPerson, _currency),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9B7FD4),
                            )),
                      if (isIncluded && _splitMode == _SplitMode.exact)
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _exactControllers[m.id],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: GlassColors.text),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixText: '${FxService.symbolFor(_currency)} ',
                              prefixStyle: const TextStyle(
                                  color: GlassColors.textMuted,
                                  fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: GlassColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: GlassColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.white54),
                              ),
                              filled: true,
                              fillColor: GlassColors.surface,
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
                                ? const Color(0xFF764BA2)
                                : GlassColors.border,
                            width: 2,
                          ),
                          color: isIncluded
                              ? const Color(0xFF764BA2)
                              : Colors.transparent,
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
              child: GestureDetector(
                onTap: _prevStep,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: GlassColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GlassColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Back',
                      style: TextStyle(
                          color: GlassColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: canSave ? _submit : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: canSave
                        ? const LinearGradient(
                            colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canSave ? null : GlassColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                      widget.expense != null
                          ? 'Save Changes'
                          : 'Save Expense',
                      style: TextStyle(
                          color: canSave
                              ? Colors.white
                              : GlassColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF764BA2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : GlassColors.textMuted,
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
        height: 4,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF764BA2) : GlassColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}


Future<String?> _pickCurrency(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A1535),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text("Select currency",
                  style: TextStyle(
                      color: GlassColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: FxService.supportedCurrencies.map((code) {
                    final picked = code == current;
                    return InkWell(
                      onTap: () => Navigator.pop(sheetCtx, code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: picked
                              ? const Color(0xFF764BA2).withValues(alpha: 0.2)
                              : GlassColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: picked
                                  ? const Color(0xFF764BA2)
                                  : GlassColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(FxService.symbolFor(code),
                                  style: const TextStyle(
                                      color: GlassColors.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ),
                            Expanded(
                              child: Text(code,
                                  style: const TextStyle(
                                      color: GlassColors.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                            if (picked)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF9B7FD4), size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
