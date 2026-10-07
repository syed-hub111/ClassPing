import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/parent_provider.dart';

class ParentShellScreen extends ConsumerWidget {
  final Widget child;

  const ParentShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final notifsAsync = ref.watch(parentNotificationsProvider);
    final unreadCount = notifsAsync.value?.where((n) => !n.isRead).length ?? 0;

    final navItems = [
      (label: 'Dashboard', route: '/parent/dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
      (label: 'Attendance History', route: '/parent/history', icon: Icons.history_rounded, activeIcon: Icons.history_rounded),
      (label: 'Child Comparison', route: '/parent/compare', icon: Icons.compare_arrows_rounded, activeIcon: Icons.compare_arrows_rounded),
      (label: 'Tutor Information', route: '/parent/tutor-info', icon: Icons.school_outlined, activeIcon: Icons.school),
      (label: 'Notifications', route: '/parent/notifications', icon: Icons.notifications_outlined, activeIcon: Icons.notifications),
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
                  child: const Icon(Icons.family_restroom_rounded, color: AppTheme.primary, size: 22),
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
                      'Parent Portal',
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
                final isNotif = item.route == '/parent/notifications';

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
                    trailing: (isNotif && unreadCount > 0)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.absent, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                    onTap: () => context.go(item.route),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          ListTile(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Portal'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppTheme.absent, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.go('/parent/notifications'),
          ),
        ],
      ),
      drawer: Drawer(child: sidebar),
      body: child,
    );
  }
}
