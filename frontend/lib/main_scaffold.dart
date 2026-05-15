/*
 * main_scaffold.dart — Bottom-navigation shell
 *
 * Holds the 4-tab layout: Home, Groups, Add (+), Profile.
 * Activity used to be a top-level tab; it now lives as a section on the
 * Profile page that pushes ActivityScreen as a route.
 * Uses IndexedStack to keep tab state alive when switching.
 * The middle "Add" tab pushes a full-screen AddExpenseScreen instead of
 * staying in the tab, so it doesn't interfere with the bottom nav.
 */
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/screens/home_screen.dart';
import 'package:splitease/screens/groups_screen.dart';
import 'package:splitease/screens/profile_screen.dart';
import 'package:splitease/screens/group_detail_screen.dart';
import 'package:splitease/screens/add_expense_screen.dart';
import 'package:splitease/theme/app_theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  String? _lastShownError;

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
    final app = context.watch<AppProvider>();

    // Surface any backend sync failure as a snackbar so the user sees what
    // went wrong instead of staring at silently-disappearing data.
    final err = app.lastSyncError;
    if (err != null && err != _lastShownError) {
      _lastShownError = err;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.clearSnackBars();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(err),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () => app.clearSyncError(),
            ),
          ),
        );
      });
    }

    final screens = [
      HomeScreen(onGroupSelect: _onGroupSelect),
      GroupsScreen(onGroupSelect: _onGroupSelect),
      const SizedBox.shrink(), // placeholder for add tab
      ProfileScreen(onGroupSelect: _onGroupSelect),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen gradient background shared by all tabs
          Container(
            decoration: const BoxDecoration(gradient: GlassColors.bgGradient),
          ),
          // Tab content
          IndexedStack(
            index: _currentIndex.clamp(0, screens.length - 1),
            children: screens,
          ),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1535).withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                // Stack lets the FAB visually sit on top of the bar without
                // forcing the Row height to grow. The Row only holds nav items
                // (one of which is a spacer that reserves the centered FAB slot).
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Row(
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
                        // Invisible spacer: reserves room for the FAB so the
                        // surrounding items don't slide under it.
                        const SizedBox(width: 56),
                        _NavItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          isActive: _currentIndex == 3,
                          onTap: () => _onTabChange(3),
                        ),
                      ],
                    ),
                    // Centered FAB
                    Positioned(
                      top: -8,
                      child: GestureDetector(
                        onTap: () => _onTabChange(2),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF764BA2)
                                    .withValues(alpha: 0.5),
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
                  ],
                ),
              ),
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
    final color = isActive ? Colors.white : Colors.white.withValues(alpha: 0.45);

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
                    ? Colors.white.withValues(alpha: 0.15)
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
