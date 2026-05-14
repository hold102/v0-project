/*
 * main_scaffold.dart — Bottom-navigation shell
 *
 * Holds the 5-tab layout: Home, Groups, Add (+), Activity, Profile.
 * Uses IndexedStack to keep tab state alive when switching.
 * The middle "Add" tab pushes a full-screen AddExpenseScreen instead of
 * staying in the tab, so it doesn't interfere with the bottom nav.
 */
import 'package:flutter/material.dart';
import 'package:splitease/screens/home_screen.dart';
import 'package:splitease/screens/groups_screen.dart';
import 'package:splitease/screens/activity_screen.dart';
import 'package:splitease/screens/profile_screen.dart';
import 'package:splitease/screens/group_detail_screen.dart';
import 'package:splitease/screens/add_expense_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _onTabChange(int index) {
    if (index == 2) {
      // The center "Add" button pushes a full-screen route instead of changing the tab
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddExpenseScreen(),
        ),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _onGroupSelect(String groupId) {
    // Pushes the group detail screen — called from Home/Activity when a group is tapped
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(groupId: groupId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final screens = [
      HomeScreen(onGroupSelect: _onGroupSelect),
      GroupsScreen(onGroupSelect: _onGroupSelect),
      const SizedBox.shrink(), // placeholder for add tab
      ActivityScreen(onGroupSelect: _onGroupSelect),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex.clamp(0, screens.length - 1),
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTabChange(0),
                ),
                _NavItem(
                  icon: Icons.group_rounded,
                  label: 'Groups',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTabChange(1),
                ),
                // Add button (prominent)
                GestureDetector(
                  onTap: () => _onTabChange(2),
                  child: Transform.translate(
                    offset: const Offset(0, -8),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.article_rounded,
                  label: 'Activity',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTabChange(3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => _onTabChange(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
