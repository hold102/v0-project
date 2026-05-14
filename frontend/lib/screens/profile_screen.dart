/*
 * profile_screen.dart — User profile and settings
 * Shows avatar, name, email, stat cards (groups, total spent, owed/owing),
 * a settings menu (placeholder), and a logout button.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final totalExpenses =
            app.groups.fold<double>(0, (sum, g) => sum + g.totalExpenses);
        final totalOwed = app.getTotalOwed();
        final totalOwing = app.getTotalOwing();

        final menuItems = [
          _MenuItem(Icons.notifications_outlined, 'Notifications',
              'Manage push notifications', Colors.blue),
          _MenuItem(Icons.dark_mode_outlined, 'Dark mode',
              'Switch app appearance', Colors.indigo),
          _MenuItem(Icons.credit_card_outlined, 'Payment methods',
              'Manage your payment methods', Color(0xFF059669)),
          _MenuItem(Icons.shield_outlined, 'Privacy and security',
              'Account security settings', Colors.amber),
          _MenuItem(Icons.settings_outlined, 'Account settings',
              'Manage your account', Colors.grey),
          _MenuItem(
              Icons.help_outline, 'Help and support', 'FAQs', Colors.purple),
        ];

        return ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const SizedBox(height: 60),
            // Profile header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
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
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(app.currentUser.email ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Stats grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    title: '${app.groups.length}',
                    subtitle: 'Active groups',
                    color: null,
                  ),
                  _StatCard(
                    title: 'RM ${totalExpenses.toStringAsFixed(0)}',
                    subtitle: 'Total spent',
                    color: null,
                  ),
                  _StatCard(
                    title: 'RM ${totalOwed.toStringAsFixed(2)}',
                    subtitle: 'Owed to you',
                    color: Color(0xFF059669),
                  ),
                  _StatCard(
                    title: 'RM ${totalOwing.toStringAsFixed(2)}',
                    subtitle: 'You owe',
                    color: Color(0xFFE11D48),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Menu items
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Settings',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            ...menuItems.map((item) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                  child: Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      title: Text(item.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text(item.description,
                          style: const TextStyle(fontSize: 12)),
                      trailing: Icon(Icons.chevron_right,
                          color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onTap: () {},
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.logout_rounded,
                        color: Color(0xFFE11D48), size: 22),
                  ),
                  title: Text('Log out',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE11D48),
                          fontSize: 15)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  onTap: () => context.read<AppProvider>().logout(),  // fire-and-forget: clears prefs then notifies
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App footer
            Center(
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💸', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 6),
                        Text('SplitEase',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('v1.0.0',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  const _MenuItem(this.icon, this.label, this.description, this.color);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? color;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    final bg = c?.withValues(alpha: 0.08);
    final border = c?.withValues(alpha: 0.3) ?? Colors.grey.shade200;
    final textColor = c ?? Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}
