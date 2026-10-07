import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';

class AdminShellScreen extends ConsumerWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final navItems = [
      (label: 'Dashboard', route: '/admin/dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
      (label: 'Students', route: '/admin/students', icon: Icons.school_outlined, activeIcon: Icons.school),
      (label: 'Tutors', route: '/admin/tutors', icon: Icons.person_outline, activeIcon: Icons.person),
      (label: 'Classes', route: '/admin/classes', icon: Icons.meeting_room_outlined, activeIcon: Icons.meeting_room),
      (label: 'Academic Years', route: '/admin/academic-years', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
      (label: 'Promotion', route: '/admin/promotion', icon: Icons.upgrade_outlined, activeIcon: Icons.upgrade),
      (label: 'Pending Attendance', route: '/admin/pending', icon: Icons.pending_actions_outlined, activeIcon: Icons.pending_actions),
    ];

    Widget sidebar = Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Admin Portal',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: navItems.map((item) {
                final isSelected = location.startsWith(item.route);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    selected: isSelected,
                    selectedTileColor: AppTheme.primary.withAlpha(20),
                    selectedColor: AppTheme.primary,
                    leading: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () => context.go(item.route),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.absent, size: 20),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.absent, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile / Tablet with Drawer
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
      ),
      drawer: Drawer(child: sidebar),
      body: child,
    );
  }
}
