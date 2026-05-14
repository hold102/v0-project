import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/services/api_service.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late String _name;
  late String _emoji;
  late List<User> _members;
  bool _saving = false;
  late final TextEditingController _nameController;
  final TextEditingController _emailController = TextEditingController();
  String? _lookupError;
  bool _lookupLoading = false;

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
      _members = List<User>.from(group.members);
    } else {
      _name = '';
      _emoji = '🎉';
      _members = [];
    }
    _nameController = TextEditingController(text: _name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.trim().isEmpty || _members.length < 2) return;
    setState(() => _saving = true);

    final app = context.read<AppProvider>();
    app.updateGroup(widget.groupId, name: _name.trim(), emoji: _emoji, members: _members);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Edit Group',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      final selected = _emoji == e;
                      return GestureDetector(
                        onTap: () => setState(() => _emoji = e),
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Weekend Dinner',
                      labelText: 'Group Name',
                    ),
                    onChanged: (v) => _name = v,
                  ),
                  const SizedBox(height: 24),
                  // Member lookup
                  Text('Members (${_members.length})',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter email to add member',
                            errorText: _lookupError,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _lookupLoading
                              ? null
                              : () async {
                                  final email = _emailController.text.trim();
                                  if (email.isEmpty) return;
                                  setState(() {
                                    _lookupError = null;
                                    _lookupLoading = true;
                                  });
                                  try {
                                    final user = await ApiService()
                                        .lookupUserByEmail(email);
                                    if (_members.any((m) => m.id == user.id)) {
                                      setState(() {
                                        _lookupError = 'Already a member.';
                                        _lookupLoading = false;
                                      });
                                      return;
                                    }
                                    setState(() {
                                      _members = [..._members, user];
                                      _emailController.clear();
                                      _lookupLoading = false;
                                    });
                                  } catch (e) {
                                    setState(() {
                                      _lookupError = e
                                          .toString()
                                          .replaceFirst('Exception: ', '');
                                      _lookupLoading = false;
                                    });
                                  }
                                },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _lookupLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                  if (_members.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _members.map((u) {
                        final isSelf = u.id == app.currentUser.id;
                        return Chip(
                          avatar: Text(u.avatar,
                              style: const TextStyle(fontSize: 14)),
                          label: Text(u.name),
                          deleteIcon:
                              isSelf ? null : const Icon(Icons.close, size: 16),
                          onDeleted: isSelf
                              ? null
                              : () => setState(() => _members =
                                  _members.where((m) => m.id != u.id).toList()),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed:
                        _name.trim().isNotEmpty && _members.length >= 2 && !_saving
                            ? _save
                            : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
