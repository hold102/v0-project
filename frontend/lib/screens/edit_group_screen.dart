import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late String _name;
  late String _emoji;
  late List<String> _memberIds;
  bool _saving = false;

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
      _memberIds = group.members.map((m) => m.id).toList();
    } else {
      _name = '';
      _emoji = '🎉';
      _memberIds = [];
    }
  }

  void _save() {
    if (_name.trim().isEmpty || _memberIds.length < 2) return;
    setState(() => _saving = true);

    final app = context.read<AppProvider>();
    final members = app.users.where((u) => _memberIds.contains(u.id)).toList();
    app.updateGroup(widget.groupId, name: _name.trim(), emoji: _emoji, members: members);
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
                    controller: TextEditingController(text: _name),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Weekend Dinner',
                      labelText: 'Group Name',
                    ),
                    onChanged: (v) => _name = v,
                  ),
                  const SizedBox(height: 24),
                  // Member selection
                  Text('Select Members (${_memberIds.length})',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: app.users.map((u) {
                      final selected = _memberIds.contains(u.id);
                      final isSelf = u.id == app.currentUser.id;
                      return GestureDetector(
                        onTap: isSelf
                            ? null
                            : () {
                                setState(() {
                                  if (selected) {
                                    _memberIds.remove(u.id);
                                  } else {
                                    _memberIds.add(u.id);
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
                                child: Text(u.avatar, style: const TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(u.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500, fontSize: 14))),
                              if (selected)
                                Icon(Icons.check_circle,
                                    size: 20, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed:
                        _name.trim().isNotEmpty && _memberIds.length >= 2 && !_saving
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
