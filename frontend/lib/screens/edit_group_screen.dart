import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/theme/app_theme.dart';
import 'package:splitease/widgets/user_search_field.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late String _name;
  late String _emoji;
  late String _description;
  late List<User> _members;
  bool _saving = false;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  static const _emojis = [
    '🍕', '✈️', '🏠', '🎉', '💼', '🎮', '🛒', '☕', '🎬', '🏖️',
  ];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final group = app.getGroupById(widget.groupId);
    if (group != null) {
      _name = group.name;
      _emoji = group.emoji;
      _description = group.description;
      _members = List<User>.from(group.members);
    } else {
      _name = '';
      _emoji = '🎉';
      _description = '';
      _members = [];
    }
    _nameController = TextEditingController(text: _name);
    _descriptionController = TextEditingController(text: _description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.trim().isEmpty || _members.length < 2) return;
    setState(() => _saving = true);
    final app = context.read<AppProvider>();
    app.updateGroup(
      widget.groupId,
      name: _name.trim(),
      emoji: _emoji,
      description: _description.trim(),
      members: _members,
    );
    Navigator.of(context).pop(true);
  }

  InputDecoration _glassInput({required String hint, String? label, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      errorText: errorText,
      hintStyle: const TextStyle(color: GlassColors.textMuted),
      labelStyle: const TextStyle(color: GlassColors.textMuted),
      errorStyle: const TextStyle(color: GlassColors.negative),
      filled: true,
      fillColor: GlassColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final canSave = _name.trim().isNotEmpty && _members.length >= 2 && !_saving;

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
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                      const Expanded(
                        child: Text('Edit Group',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: GlassColors.text)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
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
                          final selected = _emoji == e;
                          return GestureDetector(
                            onTap: () => setState(() => _emoji = e),
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
                        controller: _nameController,
                        style: const TextStyle(color: GlassColors.text),
                        decoration: _glassInput(
                          hint: 'e.g. Weekend Dinner',
                          label: 'Group Name',
                        ),
                        onChanged: (v) => _name = v,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        style: const TextStyle(color: GlassColors.text),
                        minLines: 1,
                        maxLines: 3,
                        decoration: _glassInput(
                          hint: 'What\'s this group for? (optional)',
                          label: 'Description',
                        ),
                        onChanged: (v) => _description = v,
                      ),
                      const SizedBox(height: 24),
                      Text('Members (${_members.length})',
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
                                _members.any((m) => m.id == friend.id);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (picked) {
                                  _members = _members
                                      .where((m) => m.id != friend.id)
                                      .toList();
                                } else {
                                  _members = [..._members, friend];
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
                                        style:
                                            const TextStyle(fontSize: 14)),
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
                        excludeIds: _members.map((m) => m.id).toSet(),
                        onUserSelected: (user) =>
                            setState(() => _members = [..._members, user]),
                      ),
                      if (_members.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _members.map((u) {
                            final isSelf = u.id == app.currentUser.id;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: GlassColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: GlassColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(u.avatar,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(isSelf ? 'You' : u.name,
                                      style: const TextStyle(
                                          color: GlassColors.text,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  if (!isSelf) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setState(() => _members =
                                          _members
                                              .where((m) => m.id != u.id)
                                              .toList()),
                                      child: const Icon(Icons.close,
                                          size: 14,
                                          color: GlassColors.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: canSave ? _save : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                            _saving ? 'Saving...' : 'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: canSave ? Colors.white : GlassColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
