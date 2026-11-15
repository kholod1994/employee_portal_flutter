import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/portal_provider.dart';
import '../screens/attendance_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leave_screen.dart';
import '../screens/settings_screen.dart';
import 'glassy_nav_bar.dart';

class PortalBottomNavigation extends StatelessWidget {
  final int selectedIndex;

  const PortalBottomNavigation({
    super.key,
    required this.selectedIndex,
  });

  static const _routes = ['/home', '/attendance', '/leave', '/settings'];

  static const _items = [
    NavItemData(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    NavItemData(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'الحضور',
    ),
    NavItemData(
      icon: Icons.beach_access_outlined,
      selectedIcon: Icons.beach_access_rounded,
      label: 'الإجازات',
    ),
    NavItemData(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'الإعدادات',
    ),
  ];

  static Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const AttendanceScreen();
      case 2:
        return const LeaveScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  void _navigateTo(BuildContext context, int index) {
    if (index == selectedIndex) return;

    final isForward = index > selectedIndex;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dx = isRtl ? (isForward ? -0.08 : 0.08) : (isForward ? 0.08 : -0.08);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        settings: RouteSettings(name: _routes[index]),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _buildScreen(index),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(dx, 0.0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<PortalProvider>().navBarStyle;

    return GlassyNavBar(
      selectedIndex: selectedIndex,
      style: style,
      items: _items,
      onDestinationSelected: (index) => _navigateTo(context, index),
    );
  }
}
