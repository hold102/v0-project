import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/models/user.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/screens/activity_screen.dart';
import 'package:splitease/services/fx_service.dart';
import 'package:splitease/widgets/glass_card.dart';
import 'package:splitease/widgets/user_search_field.dart';
import 'package:splitease/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  // Passed down so the Activity screen can deep-link into a group's detail.
  final void Function(String groupId)? onGroupSelect;
  const ProfileScreen({super.key, this.onGroupSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final totalOwed = app.getTotalOwed();
        final totalOwing = app.getTotalOwing();


        return ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20),
            // Profile header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: GlassColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(app.currentUser.avatar,
                        style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.currentUser.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: GlassColors.text)),
                        const SizedBox(height: 2),
                        Text(app.currentUser.email ?? '',
                            style: const TextStyle(
                                color: GlassColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Stats grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    title: 'RM ${totalOwed.toStringAsFixed(2)}',
                    subtitle: 'Owed to you',
                    accentColor: GlassColors.positive,
                  ),
                  _StatCard(
                    title: 'RM ${totalOwing.toStringAsFixed(2)}',
                    subtitle: 'You owe',
                    accentColor: GlassColors.negative,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Friend requests + friends list
            _FriendsSection(
              incomingRequests: app.incomingRequests,
              friends: app.friends,
              onAccept: (id) => context.read<AppProvider>().acceptFriendRequest(id),
              onReject: (id) => context.read<AppProvider>().rejectFriendRequest(id),
            ),
            const SizedBox(height: 20),
            // Preferred currency selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassTile(
                borderRadius: 16,
                onTap: () => _showCurrencyPicker(context, app.currentUser.currency),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF34D399).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.payments_rounded,
                          color: Color(0xFF34D399), size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Preferred currency',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: GlassColors.text,
                              fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: GlassColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GlassColors.border),
                      ),
                      child: Text(
                        '${FxService.symbolFor(app.currentUser.currency)} ${app.currentUser.currency}',
                        style: const TextStyle(
                            color: GlassColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: GlassColors.textMuted, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Activity entry — pushes the full ActivityScreen as a route
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassTile(
                borderRadius: 16,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        iconTheme:
                            const IconThemeData(color: GlassColors.text),
                        title: const Text('Activity',
                            style: TextStyle(
                                color: GlassColors.text,
                                fontWeight: FontWeight.bold)),
                      ),
                      body: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                                gradient: GlassColors.bgGradient),
                          ),
                          ActivityScreen(
                              onGroupSelect: onGroupSelect ?? (_) {}),
                        ],
                      ),
                    ),
                  ));
                },
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF764BA2).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.article_rounded,
                          color: Color(0xFF9B7FD4), size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Activity',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: GlassColors.text,
                              fontSize: 15)),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: GlassColors.textMuted, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Log out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassTile(
                borderRadius: 16,
                onTap: () => context.read<AppProvider>().logout(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GlassColors.negative.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.logout_rounded,
                          color: GlassColors.negative, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Text('Log out',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: GlassColors.negative,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Footer
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: GlassColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlassColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💸', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 6),
                        Text('SplitEase',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: GlassColors.text)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('v1.0.0',
                      style: TextStyle(
                          color: GlassColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _showCurrencyPicker(BuildContext context, String current) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1535),
    isScrollControlled: true, // allow the sheet to grow past 50% height
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
              const Text('Select preferred currency',
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
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        if (!picked) {
                          await context
                              .read<AppProvider>()
                              .updateMyCurrency(code);
                        }
                      },
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

class _FriendsSection extends StatelessWidget {
  final List<User> incomingRequests;
  final List<User> friends;
  final Future<bool> Function(String userId) onAccept;
  final Future<bool> Function(String userId) onReject;

  const _FriendsSection({
    required this.incomingRequests,
    required this.friends,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Add Friend'),
          const SizedBox(height: 10),
          // UserSearchField already drives the full friend-request flow:
          // searching, status badges, and the "Send friend request" dialog.
          // We pass an empty selection callback because there's no group to add to here —
          // the user just wants to send a request and let the recipient accept.
          UserSearchField(
            excludeIds: const {},
            onUserSelected: (_) {},
          ),
          const SizedBox(height: 24),
          if (incomingRequests.isNotEmpty) ...[
            _SectionLabel(
              label: 'Friend Requests (${incomingRequests.length})',
            ),
            const SizedBox(height: 10),
            ...incomingRequests.map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RequestTile(
                  user: u,
                  onAccept: () => onAccept(u.id),
                  onReject: () => onReject(u.id),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          _SectionLabel(label: 'Friends (${friends.length})'),
          const SizedBox(height: 10),
          if (friends.isEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: GlassColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GlassColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.people_outline_rounded,
                      color: GlassColors.textMuted, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No friends yet. Search a user when adding to a group to send a friend request.',
                      style: TextStyle(
                          color: GlassColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            ...friends.map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FriendTile(user: u),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: GlassColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700));
  }
}

class _RequestTile extends StatelessWidget {
  final User user;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestTile({
    required this.user,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: GlassColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassColors.border),
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
            child: Text(user.avatar, style: const TextStyle(fontSize: 18)),
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
                if (user.email != null && user.email!.isNotEmpty)
                  Text(user.email!,
                      style: const TextStyle(
                          color: GlassColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onReject,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: GlassColors.negative.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: GlassColors.negative.withValues(alpha: 0.35)),
              ),
              child: const Text('Reject',
                  style: TextStyle(
                      color: GlassColors.negative,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          GestureDetector(
            onTap: onAccept,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Accept',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final User user;
  const _FriendTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: GlassColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassColors.border),
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
            child: Text(user.avatar, style: const TextStyle(fontSize: 18)),
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
                if (user.email != null && user.email!.isNotEmpty)
                  Text(user.email!,
                      style: const TextStyle(
                          color: GlassColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF34D399), size: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? accentColor;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = accentColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c != null ? c.withValues(alpha: 0.12) : GlassColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c != null ? c.withValues(alpha: 0.3) : GlassColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: c ?? GlassColors.text)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: GlassColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
