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
      // Add tab — push full screen
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
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                    offset: const Offset(0, -12),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
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
    final color = isActive ? colorScheme.primary : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isActive ? 26 : 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
