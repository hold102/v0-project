/*
 * user_search_field.dart — Debounced user search with friendship gating
 *
 * Search results show a status badge based on the current user's relationship
 * with each result: Friend (selectable), Pending (after sending request),
 * or "Add Friend" (which fires a confirmation dialog before sending a request).
 * Only friends (and self) invoke onUserSelected; everyone else is gated
 * behind a friend request first.
 */
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/services/api_service.dart';
import 'package:splitease/theme/app_theme.dart';

class UserSearchField extends StatefulWidget {
  final void Function(User user) onUserSelected;
  final Set<String> excludeIds;

  const UserSearchField({
    super.key,
    required this.onUserSelected,
    this.excludeIds = const {},
  });

  @override
  State<UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<UserSearchField> {
  final _controller = TextEditingController();
  List<User> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await ApiService().searchUsers(value.trim());
        final filtered =
            results.where((u) => !widget.excludeIds.contains(u.id)).toList();
        if (mounted) {
          setState(() {
            _results = filtered;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _error = 'Search failed.';
            _loading = false;
          });
        }
      }
    });
  }

  void _clearResults() {
    _controller.clear();
    setState(() {
      _results = [];
      _error = null;
    });
  }

  Future<void> _handleTap(AppProvider app, User user) async {
    final status = app.friendStatusFor(user.id);
    if (status == 'friend' || status == 'self') {
      _clearResults();
      widget.onUserSelected(user);
      return;
    }
    if (status == 'outgoing') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request already sent to ${user.name}.')),
      );
      return;
    }
    if (status == 'incoming') {
      // They already requested us — confirm acceptance, then select
      final ok = await _confirmAccept(user);
      if (!mounted || ok != true) return;
      final accepted = await app.acceptFriendRequest(user.id);
      if (!mounted) return;
      if (accepted) {
        _clearResults();
        widget.onUserSelected(user);
      }
      return;
    }
    // status == 'none' → offer to send a friend request
    final ok = await _confirmSend(user);
    if (!mounted || ok != true) return;
    final sent = await app.sendFriendRequest(user.id);
    if (!mounted) return;
    if (sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Friend request sent to ${user.name}. They\'ll appear once accepted.'),
        ),
      );
    }
  }

  Future<bool?> _confirmSend(User user) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1535),
        title: Text('Add ${user.name} as a friend?',
            style: const TextStyle(color: GlassColors.text)),
        content: const Text(
          'You can only add friends to a group. Send a friend request first?',
          style: TextStyle(color: GlassColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: GlassColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmAccept(User user) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1535),
        title: Text('Accept ${user.name}\'s friend request?',
            style: const TextStyle(color: GlassColors.text)),
        content: const Text(
          'They\'ve already invited you. Accept and add them?',
          style: TextStyle(color: GlassColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: GlassColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case 'friend':
      case 'self':
        return const Icon(Icons.add_circle_outline_rounded,
            color: Color(0xFF9B7FD4), size: 22);
      case 'outgoing':
        return _Pill(label: 'Pending', color: GlassColors.textMuted);
      case 'incoming':
        return _Pill(label: 'Accept', color: const Color(0xFF34D399));
      default:
        return _Pill(label: 'Add friend', color: const Color(0xFF9B7FD4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: GlassColors.text),
          decoration: InputDecoration(
            hintText: 'Search by name or email',
            hintStyle: const TextStyle(color: GlassColors.textMuted),
            filled: true,
            fillColor: GlassColors.surface,
            prefixIcon: const Icon(Icons.search_rounded,
                color: GlassColors.textMuted, size: 20),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _clearResults,
                        child: const Icon(Icons.close_rounded,
                            color: GlassColors.textMuted, size: 18),
                      )
                    : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
          onChanged: _onChanged,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(_error!,
                style: const TextStyle(
                    color: GlassColors.negative, fontSize: 12)),
          ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1535),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: _results.map((user) {
                  final status = app.friendStatusFor(user.id);
                  return InkWell(
                    onTap: () => _handleTap(app, user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: _results.last.id != user.id
                            ? const Border(
                                bottom:
                                    BorderSide(color: GlassColors.border))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(user.avatar,
                                style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                    style: const TextStyle(
                                        color: GlassColors.text,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                if (user.email != null &&
                                    user.email!.isNotEmpty)
                                  Text(user.email!,
                                      style: const TextStyle(
                                          color: GlassColors.textMuted,
                                          fontSize: 12)),
                              ],
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        if (_results.isEmpty &&
            !_loading &&
            _controller.text.trim().isNotEmpty &&
            _error == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: GlassColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GlassColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_rounded,
                      size: 16, color: GlassColors.textMuted),
                  SizedBox(width: 8),
                  Text('No users found',
                      style: TextStyle(
                          color: GlassColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
